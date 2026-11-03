import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../events/data/event_revision.dart';
import '../../groups/domain/group.dart';
import '../domain/participant.dart';
import '../domain/person.dart';
import '../domain/phone_number.dart';
import '../domain/validation.dart';

DateTime _systemNow() => DateTime.now().toUtc();
String _systemId() => const Uuid().v4();

/// Persistência de participações por evento.
class ParticipantRepository {
  ParticipantRepository(
    this._database, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? _systemNow,
       _newId = newId ?? _systemId;

  final Database _database;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<List<Participant>> getByEvent(String eventId) async {
    final records = await participantsStore.find(
      _database,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final participants = records
        .map((record) => Participant.fromMap(record.value))
        .toList(growable: false);
    participants.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return participants;
  }

  Future<List<Participant>> getAll() async {
    final records = await participantsStore.find(_database);
    return records
        .map((record) => Participant.fromMap(record.value))
        .toList(growable: false);
  }

  Future<Participant?> getById(String id) async {
    final record = await participantsStore.record(id).get(_database);
    return record == null ? null : Participant.fromMap(record);
  }

  /// Cria uma pessoa e a participação no evento em uma única transação.
  Future<Participant> createWithNewPerson({
    required String eventId,
    required String name,
    String? nickname,
    String? phoneE164,
    String? guardianPersonId,
    bool isActive = true,
    Set<String> groupIds = const {},
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validatePersonName(normalizedName);
    if (nameError != null) {
      throw ValidationException(nameError);
    }
    final normalizedNickname = _nullableText(nickname);
    final nicknameError = validateNickname(normalizedNickname);
    if (nicknameError != null) {
      throw ValidationException(nicknameError);
    }
    if (!isValidE164(phoneE164)) {
      throw const ValidationException('Telefone inválido.');
    }

    final now = _now();
    final person = Person(
      id: _newId(),
      name: normalizedName,
      nickname: normalizedNickname,
      phoneE164: phoneE164,
      createdAt: now,
      updatedAt: now,
    );

    final participant = Participant(
      id: _newId(),
      eventId: eventId,
      personId: person.id,
      isActive: isActive,
      guardianPersonId: guardianPersonId,
      createdAt: now,
      updatedAt: now,
    );

    await _database.transaction((txn) async {
      await ensureEventEditable(txn, eventId);
      await _ensureGuardianValid(txn, guardianPersonId, person.id);
      await peopleStore.record(person.id).put(txn, person.toMap());
      await participantsStore
          .record(participant.id)
          .put(txn, participant.toMap());
      await _syncGroups(txn, eventId, participant.id, groupIds, now);
      await bumpEventRevision(txn, eventId, now);
    });

    return participant;
  }

  /// Cria a participação de uma pessoa já cadastrada.
  Future<Participant> createWithExistingPerson({
    required String eventId,
    required String personId,
    String? guardianPersonId,
    bool isActive = true,
    Set<String> groupIds = const {},
  }) async {
    final now = _now();
    final participant = Participant(
      id: _newId(),
      eventId: eventId,
      personId: personId,
      isActive: isActive,
      guardianPersonId: guardianPersonId,
      createdAt: now,
      updatedAt: now,
    );

    await _database.transaction((txn) async {
      await ensureEventEditable(txn, eventId);
      final personRecord = await peopleStore.record(personId).get(txn);
      if (personRecord == null) {
        throw const EntityNotFoundException('Pessoa não encontrada.');
      }
      await _ensureNoDuplicate(txn, eventId, personId);
      await _ensureGuardianValid(txn, guardianPersonId, personId);
      await participantsStore
          .record(participant.id)
          .put(txn, participant.toMap());
      await _syncGroups(txn, eventId, participant.id, groupIds, now);
      await bumpEventRevision(txn, eventId, now);
    });

    return participant;
  }

  /// Atualiza a pessoa vinculada, o responsável, a situação e os grupos.
  Future<Participant> updateParticipant({
    required String participantId,
    required String name,
    String? nickname,
    String? phoneE164,
    String? guardianPersonId,
    required bool isActive,
    required Set<String> groupIds,
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validatePersonName(normalizedName);
    if (nameError != null) {
      throw ValidationException(nameError);
    }
    final normalizedNickname = _nullableText(nickname);
    final nicknameError = validateNickname(normalizedNickname);
    if (nicknameError != null) {
      throw ValidationException(nicknameError);
    }
    if (!isValidE164(phoneE164)) {
      throw const ValidationException('Telefone inválido.');
    }

    final now = _now();
    late Participant updated;

    await _database.transaction((txn) async {
      final record = await participantsStore.record(participantId).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Participante não encontrado.');
      }
      final current = Participant.fromMap(record);

      final personRecord = await peopleStore.record(current.personId).get(txn);
      if (personRecord == null) {
        throw const EntityNotFoundException('Pessoa não encontrada.');
      }
      final person = Person.fromMap(personRecord);

      final affectedEventIds = await _eventsReferencingPerson(
        txn,
        current.personId,
      );
      affectedEventIds.add(current.eventId);
      for (final eventId in affectedEventIds) {
        await ensureEventEditable(txn, eventId);
      }

      await _ensureGuardianValid(txn, guardianPersonId, current.personId);

      final updatedPerson = person.copyWith(
        name: normalizedName,
        nickname: normalizedNickname,
        clearNickname: normalizedNickname == null,
        phoneE164: phoneE164,
        clearPhone: phoneE164 == null,
        updatedAt: now,
      );
      await peopleStore.record(person.id).put(txn, updatedPerson.toMap());

      updated = current.copyWith(
        isActive: isActive,
        guardianPersonId: guardianPersonId,
        clearGuardian: guardianPersonId == null,
        updatedAt: now,
      );
      await participantsStore.record(participantId).put(txn, updated.toMap());

      await _syncGroups(txn, current.eventId, participantId, groupIds, now);

      for (final eventId in affectedEventIds) {
        await bumpEventRevision(txn, eventId, now);
      }
    });

    return updated;
  }

  /// Remove a participação, limpa os grupos e preserva a pessoa.
  Future<void> delete(String participantId) async {
    final now = _now();

    await _database.transaction((txn) async {
      final record = await participantsStore.record(participantId).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Participante não encontrado.');
      }
      final participant = Participant.fromMap(record);
      await ensureEventEditable(txn, participant.eventId);

      await participantsStore.record(participantId).delete(txn);

      final groups = await groupsStore.find(
        txn,
        finder: Finder(filter: Filter.equals('eventId', participant.eventId)),
      );
      for (final groupRecord in groups) {
        final group = Group.fromMap(groupRecord.value);
        if (!group.memberParticipantIds.contains(participantId)) {
          continue;
        }
        final members = group.memberParticipantIds
            .where((id) => id != participantId)
            .toList(growable: false);
        await groupsStore
            .record(group.id)
            .put(
              txn,
              group
                  .copyWith(memberParticipantIds: members, updatedAt: now)
                  .toMap(),
            );
      }

      await bumpEventRevision(txn, participant.eventId, now);
    });
  }

  Future<void> _ensureNoDuplicate(
    DatabaseClient txn,
    String eventId,
    String personId,
  ) async {
    final existing = await participantsStore.find(
      txn,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('eventId', eventId),
          Filter.equals('personId', personId),
        ]),
      ),
    );
    if (existing.isNotEmpty) {
      throw const DuplicateParticipationException();
    }
  }

  Future<void> _ensureGuardianValid(
    DatabaseClient txn,
    String? guardianPersonId,
    String personId,
  ) async {
    if (guardianPersonId == null) {
      return;
    }
    if (guardianPersonId == personId) {
      throw const ValidationException(
        'O responsável não pode ser o próprio participante.',
      );
    }
    final guardian = await peopleStore.record(guardianPersonId).get(txn);
    if (guardian == null) {
      throw const EntityNotFoundException('Responsável não encontrado.');
    }
  }

  Future<void> _syncGroups(
    DatabaseClient txn,
    String eventId,
    String participantId,
    Set<String> groupIds,
    DateTime now,
  ) async {
    final groupRecords = await groupsStore.find(
      txn,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final existingIds = groupRecords
        .map((record) => record.value['id'] as String)
        .toSet();

    if (!groupIds.every(existingIds.contains)) {
      throw const InvalidGroupMemberException();
    }

    for (final record in groupRecords) {
      final group = Group.fromMap(record.value);
      final hasMember = group.memberParticipantIds.contains(participantId);
      final shouldHaveMember = groupIds.contains(group.id);
      if (hasMember == shouldHaveMember) {
        continue;
      }

      final members = shouldHaveMember
          ? [...group.memberParticipantIds, participantId]
          : group.memberParticipantIds
                .where((id) => id != participantId)
                .toList(growable: false);

      await groupsStore
          .record(group.id)
          .put(
            txn,
            group
                .copyWith(memberParticipantIds: members, updatedAt: now)
                .toMap(),
          );
    }
  }

  Future<Set<String>> _eventsReferencingPerson(
    DatabaseClient txn,
    String personId,
  ) async {
    final participants = await participantsStore.find(txn);
    return participants
        .where((record) {
          final map = record.value;
          return map['personId'] == personId ||
              map['guardianPersonId'] == personId;
        })
        .map((record) => record.value['eventId'] as String?)
        .whereType<String>()
        .toSet();
  }

  static String? _nullableText(String? value) {
    final normalized = normalizePersonText(value ?? '');
    return normalized.isEmpty ? null : normalized;
  }
}
