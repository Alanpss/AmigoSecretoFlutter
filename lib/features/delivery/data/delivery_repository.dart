import 'package:sembast/sembast.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../draw/data/draw_records.dart';
import '../../events/domain/event.dart';
import '../../participants/domain/participant.dart';
import '../../participants/domain/person.dart';
import '../domain/delivery_status.dart';
import '../domain/message_template.dart';

DateTime _systemNow() => DateTime.now().toUtc();

/// Lê e atualiza entregas sem alterar snapshots já abertos ou confirmados.
class DeliveryRepository {
  DeliveryRepository(this._database, {DateTime Function()? now})
    : _now = now ?? _systemNow;

  final Database _database;
  final DateTime Function() _now;

  Future<List<DeliveryRecord>> getForActiveEvent(String eventId) async {
    final eventMap = await eventsStore.record(eventId).get(_database);
    if (eventMap == null) {
      throw const EntityNotFoundException('Evento não encontrado.');
    }
    final drawId = Event.fromMap(eventMap).activeDrawId;
    if (drawId == null) return const [];

    final records = await deliveriesStore.find(
      _database,
      finder: Finder(filter: Filter.equals('drawId', drawId)),
    );
    final deliveries = records
        .map((record) => DeliveryRecord.fromMap(record.value))
        .toList();
    return deliveries..sort((a, b) {
      final byOwner = a.ownerNameSnapshot.toLowerCase().compareTo(
        b.ownerNameSnapshot.toLowerCase(),
      );
      return byOwner != 0 ? byOwner : a.id.compareTo(b.id);
    });
  }

  /// Salva o modelo e, somente mediante escolha explícita, atualiza pendentes.
  Future<TemplateUpdateSummary> saveMessageTemplate({
    required String eventId,
    required String template,
    required bool updatePending,
  }) async {
    final parsedTemplate = MessageTemplate.parse(template);
    var updatedCount = 0;

    await _database.transaction((txn) async {
      final eventMap = await eventsStore.record(eventId).get(txn);
      if (eventMap == null) {
        throw const EntityNotFoundException('Evento não encontrado.');
      }
      final event = Event.fromMap(eventMap);
      final drawId = event.activeDrawId;

      if (updatePending && drawId != null) {
        final assignmentRecords = await assignmentsStore.find(
          txn,
          finder: Finder(filter: Filter.equals('drawId', drawId)),
        );
        final assignments = {
          for (final record in assignmentRecords)
            record.key: AssignmentRecord.fromMap(record.value),
        };
        final participantRecords = await participantsStore.find(
          txn,
          finder: Finder(filter: Filter.equals('eventId', eventId)),
        );
        final participants = {
          for (final record in participantRecords)
            record.key: Participant.fromMap(record.value),
        };
        final peopleRecords = await peopleStore.find(txn);
        final people = {
          for (final record in peopleRecords)
            record.key: Person.fromMap(record.value),
        };
        final deliveryRecords = await deliveriesStore.find(
          txn,
          finder: Finder(filter: Filter.equals('drawId', drawId)),
        );

        for (final record in deliveryRecords) {
          final delivery = DeliveryRecord.fromMap(record.value);
          if (delivery.status != DeliveryStatus.pending.name) continue;

          final assignment = assignments[delivery.assignmentId];
          final ownerParticipant = participants[delivery.ownerParticipantId];
          final receiverParticipant = assignment == null
              ? null
              : participants[assignment.receiverParticipantId];
          final owner = ownerParticipant == null
              ? null
              : people[ownerParticipant.personId];
          final receiver = receiverParticipant == null
              ? null
              : people[receiverParticipant.personId];
          if (owner == null || receiver == null || assignment == null) {
            throw const ValidationException(
              'Não foi possível atualizar as mensagens pendentes. '
              'Nenhuma alteração foi salva.',
            );
          }

          final updatedMessage = parsedTemplate.render({
            'evento': event.name,
            'participante': owner.name,
            'apelido': owner.nickname ?? owner.name,
            'sorteado': receiver.displayName,
            'responsavel': delivery.recipientNameSnapshot,
          });
          await deliveriesStore
              .record(record.key)
              .put(
                txn,
                delivery.copyWith(messageSnapshot: updatedMessage).toMap(),
              );
          updatedCount++;
        }
      }

      await eventsStore
          .record(eventId)
          .put(
            txn,
            event
                .copyWith(messageTemplate: template, updatedAt: _now())
                .toMap(),
          );
    });

    return TemplateUpdateSummary(updatedPendingMessages: updatedCount);
  }

  Future<DeliveryRecord> markOpened({
    required String eventId,
    required String deliveryId,
  }) async {
    return _updateActiveDelivery(
      eventId: eventId,
      deliveryId: deliveryId,
      update: (delivery) {
        if (delivery.status != DeliveryStatus.pending.name) return delivery;
        return delivery.copyWith(
          status: DeliveryStatus.opened.name,
          openedAt: _now(),
        );
      },
    );
  }

  Future<DeliveryRecord> confirmSent({
    required String eventId,
    required String deliveryId,
    required DeliveryConfirmationMethod method,
  }) {
    return _updateActiveDelivery(
      eventId: eventId,
      deliveryId: deliveryId,
      update: (delivery) {
        if (delivery.status == DeliveryStatus.confirmed.name) return delivery;
        return delivery.copyWith(
          status: DeliveryStatus.confirmed.name,
          confirmedAt: _now(),
          confirmationMethod: method.name,
        );
      },
    );
  }

  Future<DeliveryRecord> _updateActiveDelivery({
    required String eventId,
    required String deliveryId,
    required DeliveryRecord Function(DeliveryRecord delivery) update,
  }) async {
    late DeliveryRecord result;
    await _database.transaction((txn) async {
      final eventMap = await eventsStore.record(eventId).get(txn);
      if (eventMap == null) {
        throw const EntityNotFoundException('Evento não encontrado.');
      }
      final event = Event.fromMap(eventMap);
      final activeDrawId = event.activeDrawId;
      if (activeDrawId == null) {
        throw const EntityNotFoundException(
          'Não há um sorteio ativo para atualizar esta entrega.',
        );
      }

      final deliveryMap = await deliveriesStore.record(deliveryId).get(txn);
      if (deliveryMap == null) {
        throw const EntityNotFoundException('Entrega não encontrada.');
      }
      final current = DeliveryRecord.fromMap(deliveryMap);
      if (current.eventId != eventId || current.drawId != activeDrawId) {
        throw const EntityNotFoundException(
          'A entrega não pertence ao sorteio ativo deste evento.',
        );
      }
      if (!DeliveryStatus.values.any(
        (status) => status.name == current.status,
      )) {
        throw const ValidationException(
          'O estado da entrega não é reconhecido. Atualize os dados e tente novamente.',
        );
      }

      result = update(current);
      if (result != current) {
        await deliveriesStore.record(deliveryId).put(txn, result.toMap());
      }
    });
    return result;
  }
}

class TemplateUpdateSummary {
  const TemplateUpdateSummary({required this.updatedPendingMessages});

  final int updatedPendingMessages;
}
