import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../events/domain/event.dart';
import '../../groups/domain/group.dart';
import '../../participants/domain/guardian_resolver.dart';
import '../../participants/domain/participant.dart';
import '../../participants/domain/person.dart';
import '../domain/draw_models.dart';
import 'draw_records.dart';

DateTime _systemNow() => DateTime.now().toUtc();
String _systemId() => const Uuid().v4();

/// Leitura da revisão e gravação atômica do sorteio.
class DrawRepository {
  DrawRepository(
    this._database, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? _systemNow,
       _newId = newId ?? _systemId;

  final Database _database;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<DrawPreparation> prepare(String eventId) async {
    final eventMap = await eventsStore.record(eventId).get(_database);
    if (eventMap == null) {
      throw const EntityNotFoundException('Evento não encontrado.');
    }
    final event = Event.fromMap(eventMap);
    final participants = await participantsStore.find(
      _database,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final groups = await groupsStore.find(
      _database,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    return DrawPreparation(
      eventId: eventId,
      pairingRevision: event.pairingRevision,
      hasActiveDraw: event.activeDrawId != null,
      request: DrawRequest(
        participantIds: participants
            .where((r) => r.value['isActive'] as bool? ?? true)
            .map((r) => r.value['id'] as String)
            .toList(growable: false),
        groups: groups
            .map((r) {
              final g = Group.fromMap(r.value);
              return DrawGroupConstraint(
                id: g.id,
                name: g.name,
                participantIds: g.memberParticipantIds.toSet(),
                isEnabled: g.restrictionEnabled,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Future<PersistedDraw?> getActiveDraw(String eventId) async {
    final event = await eventsStore.record(eventId).get(_database);
    final drawId = event?['activeDrawId'] as String?;
    return drawId == null ? null : getDraw(drawId);
  }

  Future<PersistedDraw?> getDraw(String drawId) async {
    final drawMap = await drawsStore.record(drawId).get(_database);
    if (drawMap == null) return null;
    final assignments = await assignmentsStore.find(
      _database,
      finder: Finder(filter: Filter.equals('drawId', drawId)),
    );
    final deliveries = await deliveriesStore.find(
      _database,
      finder: Finder(filter: Filter.equals('drawId', drawId)),
    );
    return PersistedDraw(
      draw: DrawRecord.fromMap(drawMap),
      assignments: assignments
          .map((r) => AssignmentRecord.fromMap(r.value))
          .toList(growable: false),
      deliveries: deliveries
          .map((r) => DeliveryRecord.fromMap(r.value))
          .toList(growable: false),
    );
  }

  Future<PersistedDraw> saveDraw({
    required String eventId,
    required String drawId,
    required int pairingRevision,
    required Map<String, String> pairing,
  }) async {
    late PersistedDraw result;
    await _database.transaction((txn) async {
      final eventMap = await eventsStore.record(eventId).get(txn);
      if (eventMap == null) {
        throw const EntityNotFoundException('Evento não encontrado.');
      }
      final event = Event.fromMap(eventMap);

      if (event.activeDrawId == drawId) {
        final existing = await _loadDraw(txn, drawId);
        if (existing != null &&
            existing.draw.status == PersistedDrawStatus.active &&
            _samePairing(existing.pairing, pairing)) {
          result = existing;
          return;
        }
        throw const ActiveDrawExistsException();
      }
      if (event.activeDrawId != null) throw const ActiveDrawExistsException();
      if (await drawsStore.record(drawId).get(txn) != null) {
        throw const DrawIdConflictException();
      }
      if (event.pairingRevision != pairingRevision) {
        throw const PairingRevisionConflictException();
      }

      final participantRecords = await participantsStore.find(
        txn,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('eventId', eventId),
            Filter.equals('isActive', true),
          ]),
        ),
      );
      final participants = participantRecords
          .map((r) => Participant.fromMap(r.value))
          .toList();
      final activeIds = participants.map((p) => p.id).toSet();
      if (activeIds.length < 2 ||
          pairing.length != activeIds.length ||
          !pairing.keys.toSet().containsAll(activeIds) ||
          !pairing.values.toSet().containsAll(activeIds) ||
          pairing.entries.any((e) => e.key == e.value) ||
          pairing.values.toSet().length != activeIds.length) {
        throw const ValidationException(
          'O resultado não corresponde aos participantes ativos. Revise o sorteio e tente novamente.',
        );
      }

      final groupRecords = await groupsStore.find(
        txn,
        finder: Finder(filter: Filter.equals('eventId', eventId)),
      );
      for (final groupRecord in groupRecords) {
        final group = Group.fromMap(groupRecord.value);
        if (!group.restrictionEnabled) continue;
        final members = group.memberParticipantIds
            .where(activeIds.contains)
            .toSet();
        for (final giver in members) {
          if (members.contains(pairing[giver])) {
            throw const PairingRevisionConflictException();
          }
        }
      }

      final peopleRecords = await peopleStore.find(txn);
      final people = {
        for (final r in peopleRecords) r.key: Person.fromMap(r.value),
      };
      final participantById = {for (final p in participants) p.id: p};
      final draw = DrawRecord(
        id: drawId,
        eventId: eventId,
        createdAt: _now(),
        algorithmVersion: 1,
        pairingRevision: pairingRevision,
        status: PersistedDrawStatus.active,
      );
      final assignments = <AssignmentRecord>[];
      final deliveries = <DeliveryRecord>[];
      for (final entry in pairing.entries) {
        final assignmentId = _newId();
        final ownerParticipant = participantById[entry.key]!;
        final owner = people[ownerParticipant.personId];
        final receiverParticipant = participantById[entry.value]!;
        final receiver = people[receiverParticipant.personId];
        if (owner == null || receiver == null) {
          throw const PairingRevisionConflictException();
        }
        final guardian = ownerParticipant.guardianPersonId == null
            ? null
            : people[ownerParticipant.guardianPersonId];
        final recipient = resolveRecipient(
          owner: owner,
          participant: ownerParticipant,
          guardian: guardian,
        );
        final assignment = AssignmentRecord(
          id: assignmentId,
          drawId: drawId,
          eventId: eventId,
          giverParticipantId: entry.key,
          receiverParticipantId: entry.value,
        );
        final delivery = DeliveryRecord(
          id: _newId(),
          drawId: drawId,
          assignmentId: assignmentId,
          eventId: eventId,
          ownerParticipantId: entry.key,
          ownerNameSnapshot: owner.name,
          drawnNameSnapshot: receiver.displayName,
          createdAt: _now(),
          recipientKind: recipient.kind.name,
          recipientPersonId: recipient.recipient.id,
          recipientNameSnapshot: recipient.recipient.displayName,
          recipientPhoneSnapshot: recipient.phoneE164,
          channel: recipient.hasContact ? 'whatsapp' : 'manual',
          status: 'pending',
          messageSnapshot: _renderMessage(
            event,
            owner,
            receiver,
            recipient.recipient,
          ),
        );
        assignments.add(assignment);
        deliveries.add(delivery);
      }

      await drawsStore.record(drawId).put(txn, draw.toMap());
      for (final assignment in assignments) {
        await assignmentsStore
            .record(assignment.id)
            .put(txn, assignment.toMap());
      }
      for (final delivery in deliveries) {
        await deliveriesStore.record(delivery.id).put(txn, delivery.toMap());
      }
      await eventsStore
          .record(eventId)
          .put(
            txn,
            event.copyWith(activeDrawId: drawId, updatedAt: _now()).toMap(),
          );
      result = PersistedDraw(
        draw: draw,
        assignments: assignments,
        deliveries: deliveries,
      );
    });
    return result;
  }

  Future<InvalidationSummary> invalidateDraw(String eventId) async {
    late InvalidationSummary summary;
    await _database.transaction((txn) async {
      final map = await eventsStore.record(eventId).get(txn);
      if (map == null) {
        throw const EntityNotFoundException('Evento não encontrado.');
      }
      final event = Event.fromMap(map);
      final drawId = event.activeDrawId;
      if (drawId == null) {
        summary = const InvalidationSummary(opened: 0, confirmed: 0);
        return;
      }
      final drawMap = await drawsStore.record(drawId).get(txn);
      if (drawMap != null) {
        final draw = DrawRecord.fromMap(drawMap);
        await drawsStore
            .record(drawId)
            .put(
              txn,
              draw
                  .copyWith(
                    status: PersistedDrawStatus.invalidated,
                    invalidatedAt: _now(),
                  )
                  .toMap(),
            );
      }
      final deliveries = await deliveriesStore.find(
        txn,
        finder: Finder(filter: Filter.equals('drawId', drawId)),
      );
      summary = InvalidationSummary(
        opened: deliveries.where((r) => r.value['status'] == 'opened').length,
        confirmed: deliveries
            .where((r) => r.value['status'] == 'confirmed')
            .length,
      );
      await eventsStore
          .record(eventId)
          .put(
            txn,
            event.copyWith(clearActiveDrawId: true, updatedAt: _now()).toMap(),
          );
    });
    return summary;
  }

  Future<PersistedDraw?> _loadDraw(DatabaseClient client, String drawId) async {
    final map = await drawsStore.record(drawId).get(client);
    if (map == null) return null;
    final a = await assignmentsStore.find(
      client,
      finder: Finder(filter: Filter.equals('drawId', drawId)),
    );
    final d = await deliveriesStore.find(
      client,
      finder: Finder(filter: Filter.equals('drawId', drawId)),
    );
    return PersistedDraw(
      draw: DrawRecord.fromMap(map),
      assignments: a.map((r) => AssignmentRecord.fromMap(r.value)).toList(),
      deliveries: d.map((r) => DeliveryRecord.fromMap(r.value)).toList(),
    );
  }

  bool _samePairing(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  String _renderMessage(
    Event event,
    Person owner,
    Person receiver,
    Person recipient,
  ) {
    final values = <String, String>{
      'evento': event.name,
      'participante': owner.name,
      'apelido': owner.nickname ?? owner.name,
      'sorteado': receiver.displayName,
      'responsavel': recipient.displayName,
    };
    final template = event.messageTemplate;
    final tokens = RegExp(r'\{([^{}]+)\}').allMatches(template).toList();
    if (RegExp(r'\{[^{}]*\}').allMatches(template).length != tokens.length ||
        tokens.any((m) => !values.containsKey(m[1]))) {
      throw const ValidationException(
        'O modelo de mensagem contém uma variável inválida. Corrija o modelo antes de sortear.',
      );
    }
    return template.replaceAllMapped(
      RegExp(r'\{([^{}]+)\}'),
      (m) => values[m[1]] ?? m[0]!,
    );
  }
}

class InvalidationSummary {
  const InvalidationSummary({required this.opened, required this.confirmed});
  final int opened;
  final int confirmed;
}
