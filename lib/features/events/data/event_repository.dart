import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../delivery/domain/message_template.dart';
import '../../participants/domain/validation.dart';
import '../domain/event.dart';
import 'event_summary.dart';

DateTime _systemNow() => DateTime.now().toUtc();
String _systemId() => const Uuid().v4();

/// Persistência de eventos.
class EventRepository {
  EventRepository(
    this._database, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? _systemNow,
       _newId = newId ?? _systemId;

  final Database _database;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<List<Event>> getAll() async {
    final records = await eventsStore.find(_database);
    final events = records
        .map((record) => Event.fromMap(record.value))
        .toList(growable: false);
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  Future<List<EventSummary>> listSummaries() async {
    final events = await getAll();
    final participants = await participantsStore.find(_database);

    final totalByEvent = <String, int>{};
    final activeByEvent = <String, int>{};
    for (final record in participants) {
      final eventId = record.value['eventId'] as String?;
      if (eventId == null) {
        continue;
      }
      totalByEvent.update(eventId, (value) => value + 1, ifAbsent: () => 1);
      if (record.value['isActive'] as bool? ?? true) {
        activeByEvent.update(eventId, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return events
        .map(
          (event) => EventSummary(
            event: event,
            totalParticipants: totalByEvent[event.id] ?? 0,
            activeParticipants: activeByEvent[event.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<Event?> getById(String id) async {
    final record = await eventsStore.record(id).get(_database);
    return record == null ? null : Event.fromMap(record);
  }

  Future<Event> create({
    required String name,
    DateTime? eventDate,
    String? messageTemplate,
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validateEventName(
      normalizedName,
      maxLength: maxEventNameLength,
    );
    if (nameError != null) {
      throw ValidationException(nameError);
    }

    final enteredTemplate = (messageTemplate ?? defaultMessageTemplate).trim();
    final template = enteredTemplate.isEmpty
        ? defaultMessageTemplate
        : enteredTemplate;
    MessageTemplate.parse(template);

    final now = _now();
    final event = Event(
      id: _newId(),
      name: normalizedName,
      eventDate: _dateOnly(eventDate),
      defaultCountryCode: 'BR',
      messageTemplate: template.isEmpty ? defaultMessageTemplate : template,
      activeDrawId: null,
      pairingRevision: 0,
      createdAt: now,
      updatedAt: now,
    );

    await eventsStore.record(event.id).put(_database, event.toMap());
    return event;
  }

  Future<Event> update({
    required String id,
    required String name,
    DateTime? eventDate,
    required String messageTemplate,
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validateEventName(
      normalizedName,
      maxLength: maxEventNameLength,
    );
    if (nameError != null) {
      throw ValidationException(nameError);
    }

    final enteredTemplate = messageTemplate.trim();
    final template = enteredTemplate.isEmpty
        ? defaultMessageTemplate
        : enteredTemplate;
    MessageTemplate.parse(template);

    final existing = await getById(id);
    if (existing == null) {
      throw const EntityNotFoundException('Evento não encontrado.');
    }
    if (existing.activeDrawId != null && template != existing.messageTemplate) {
      throw const ValidationException(
        'O sorteio está ativo. Use o editor de mensagem para escolher se as '
        'entregas pendentes também devem ser atualizadas.',
      );
    }

    final updated = existing.copyWith(
      name: normalizedName,
      eventDate: _dateOnly(eventDate),
      clearEventDate: eventDate == null,
      messageTemplate: template,
      updatedAt: _now(),
    );

    await eventsStore.record(id).put(_database, updated.toMap());
    return updated;
  }

  /// Exclui o evento, seus participantes e seus grupos.
  ///
  /// Pessoas reutilizáveis são preservadas; podem participar de outros eventos
  /// ou continuar como contatos.
  Future<void> delete(String id) async {
    await _database.transaction((txn) async {
      final event = await eventsStore.record(id).get(txn);
      if (event == null) {
        throw const EntityNotFoundException('Evento não encontrado.');
      }

      final participants = await participantsStore.find(
        txn,
        finder: Finder(filter: Filter.equals('eventId', id)),
      );
      for (final participant in participants) {
        await participantsStore.record(participant.key).delete(txn);
      }

      final groups = await groupsStore.find(
        txn,
        finder: Finder(filter: Filter.equals('eventId', id)),
      );
      for (final group in groups) {
        await groupsStore.record(group.key).delete(txn);
      }

      await eventsStore.record(id).delete(txn);
    });
  }

  Future<void> bumpPairingRevision(String eventId) async {
    await _database.transaction((txn) async {
      final record = await eventsStore.record(eventId).get(txn);
      if (record == null) {
        return;
      }
      final event = Event.fromMap(record);
      await eventsStore
          .record(eventId)
          .put(
            txn,
            event
                .copyWith(
                  pairingRevision: event.pairingRevision + 1,
                  updatedAt: _now(),
                )
                .toMap(),
          );
    });
  }

  static DateTime? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }
    return DateTime(value.year, value.month, value.day);
  }
}
