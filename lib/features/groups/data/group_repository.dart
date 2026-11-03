import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../events/data/event_revision.dart';
import '../../participants/domain/validation.dart';
import '../domain/group.dart';

DateTime _systemNow() => DateTime.now().toUtc();
String _systemId() => const Uuid().v4();

/// Persistência de grupos e membros.
class GroupRepository {
  GroupRepository(
    this._database, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? _systemNow,
       _newId = newId ?? _systemId;

  final Database _database;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<List<Group>> getByEvent(String eventId) async {
    final records = await groupsStore.find(
      _database,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final groups = records
        .map((record) => Group.fromMap(record.value))
        .toList(growable: false);
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  Future<Group?> getById(String id) async {
    final record = await groupsStore.record(id).get(_database);
    return record == null ? null : Group.fromMap(record);
  }

  Future<Group> create({
    required String eventId,
    required String name,
    required GroupType type,
    bool restrictionEnabled = true,
    Set<String> memberParticipantIds = const {},
  }) async {
    final normalizedName = _normalizeName(name);
    final now = _now();
    final group = Group(
      id: _newId(),
      eventId: eventId,
      name: normalizedName,
      type: type,
      restrictionEnabled: restrictionEnabled,
      memberParticipantIds: memberParticipantIds.toList(growable: false),
      createdAt: now,
      updatedAt: now,
    );

    await _database.transaction((txn) async {
      await ensureEventEditable(txn, eventId);
      await _ensureUniqueName(txn, eventId, normalizedName);
      await _ensureMembersBelongToEvent(txn, eventId, memberParticipantIds);
      await groupsStore.record(group.id).put(txn, group.toMap());
      await bumpEventRevision(txn, eventId, now);
    });

    return group;
  }

  Future<Group> update({
    required String id,
    required String name,
    required GroupType type,
    required bool restrictionEnabled,
    required Set<String> memberParticipantIds,
  }) async {
    final normalizedName = _normalizeName(name);
    final now = _now();
    late Group updated;

    await _database.transaction((txn) async {
      final record = await groupsStore.record(id).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Grupo não encontrado.');
      }
      final current = Group.fromMap(record);
      await ensureEventEditable(txn, current.eventId);

      await _ensureUniqueName(
        txn,
        current.eventId,
        normalizedName,
        excludeGroupId: id,
      );
      await _ensureMembersBelongToEvent(
        txn,
        current.eventId,
        memberParticipantIds,
      );

      updated = current.copyWith(
        name: normalizedName,
        type: type,
        restrictionEnabled: restrictionEnabled,
        memberParticipantIds: memberParticipantIds.toList(growable: false),
        updatedAt: now,
      );
      await groupsStore.record(id).put(txn, updated.toMap());
      await bumpEventRevision(txn, current.eventId, now);
    });

    return updated;
  }

  Future<void> delete(String id) async {
    final now = _now();

    await _database.transaction((txn) async {
      final record = await groupsStore.record(id).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Grupo não encontrado.');
      }
      final group = Group.fromMap(record);
      await ensureEventEditable(txn, group.eventId);
      await groupsStore.record(id).delete(txn);
      await bumpEventRevision(txn, group.eventId, now);
    });
  }

  static String _normalizeName(String value) {
    final normalized = normalizePersonText(value);
    if (normalized.isEmpty) {
      throw const ValidationException('Informe o nome do grupo.');
    }
    if (normalized.length > maxGroupNameLength) {
      throw const ValidationException(
        'O nome do grupo deve ter no máximo 80 caracteres.',
      );
    }
    return normalized;
  }

  Future<void> _ensureUniqueName(
    DatabaseClient txn,
    String eventId,
    String name, {
    String? excludeGroupId,
  }) async {
    final records = await groupsStore.find(
      txn,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final normalized = name.toLowerCase();
    final conflict = records.any((record) {
      if (record.value['id'] == excludeGroupId) {
        return false;
      }
      final otherName = (record.value['name'] as String? ?? '').toLowerCase();
      return otherName == normalized;
    });
    if (conflict) {
      throw const DuplicateGroupNameException();
    }
  }

  Future<void> _ensureMembersBelongToEvent(
    DatabaseClient txn,
    String eventId,
    Set<String> memberParticipantIds,
  ) async {
    if (memberParticipantIds.isEmpty) {
      return;
    }
    final records = await participantsStore.find(
      txn,
      finder: Finder(filter: Filter.equals('eventId', eventId)),
    );
    final validIds = records
        .map((record) => record.value['id'] as String)
        .toSet();
    if (!memberParticipantIds.every(validIds.contains)) {
      throw const InvalidGroupMemberException();
    }
  }
}
