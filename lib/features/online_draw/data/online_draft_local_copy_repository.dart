import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../events/domain/event.dart';
import '../../groups/domain/group.dart';
import '../../participants/domain/participant.dart';
import '../../participants/domain/person.dart';
import '../../participants/domain/phone_number.dart';
import '../../participants/domain/validation.dart';

DateTime _now() => DateTime.now().toUtc();

/// Creates an independent local event from the organizer's browser draft.
/// Existing online assignments, links and tokens are deliberately ignored.
class OnlineDraftLocalCopyRepository {
  OnlineDraftLocalCopyRepository(this._database, {String Function()? newId})
    : _newId = newId ?? _uuid;

  final Database _database;
  final String Function() _newId;

  Future<String> createCopy(Map<String, Object?> draft) async {
    final name = normalizePersonText(draft['eventName'] as String? ?? '');
    final eventNameError = validateEventName(
      name,
      maxLength: maxEventNameLength,
    );
    if (eventNameError != null) throw FormatException(eventNameError);
    final allRows = (draft['participants'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final rows = allRows
        .where((value) {
          return [
            value['name'],
            value['recipientName'],
            value['recipientPhoneE164'],
          ].any((field) => (field as String? ?? '').trim().isNotEmpty);
        })
        .toList(growable: false);
    if (rows.any((row) => (row['name'] as String? ?? '').trim().isEmpty)) {
      throw const FormatException(
        'Complete o nome dos participantes antes de copiar o rascunho.',
      );
    }
    if (rows.isEmpty || rows.length > 200) {
      throw const FormatException(
        'A cópia precisa ter de 1 a 200 participantes.',
      );
    }
    final groupRows = (draft['groups'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);

    final eventId = _newId();
    final now = _now();
    final event = Event(
      id: eventId,
      name: name,
      eventDate: null,
      defaultCountryCode: 'BR',
      messageTemplate: defaultMessageTemplate,
      activeDrawId: null,
      pairingRevision: 0,
      createdAt: now,
      updatedAt: now,
    );

    final sourceIds = <String>{};
    final participantRecords = <Participant>[];
    final personRecords = <Person>[];
    final personByContact = <String, Person>{};
    final participantIdBySourceId = <String, String>{};
    for (final row in rows) {
      final sourceId = row['id'] as String? ?? _newId();
      if (!sourceIds.add(sourceId)) {
        throw const FormatException('Há participantes repetidos no rascunho.');
      }
      final participantName = normalizePersonText(row['name'] as String? ?? '');
      final participantError = validatePersonName(participantName);
      if (participantError != null) throw FormatException(participantError);
      final participantId = _newId();
      final selfPhone = _contactMatchesSelf(row, participantName)
          ? _optionalPhone(row['recipientPhoneE164'] as String?)
          : null;
      final person = _newPerson(
        name: participantName,
        phone: selfPhone,
        now: now,
      );
      personRecords.add(person);
      if (selfPhone != null) {
        personByContact.putIfAbsent(
          '${participantName.toLowerCase()}|$selfPhone',
          () => person,
        );
      }
      participantIdBySourceId[sourceId] = participantId;

      String? guardianId;
      final recipientName = normalizePersonText(
        row['recipientName'] as String? ?? '',
      );
      if (recipientName.isNotEmpty &&
          recipientName.toLowerCase() != participantName.toLowerCase()) {
        final phone = _optionalPhone(row['recipientPhoneE164'] as String?);
        final key = '${recipientName.toLowerCase()}|${phone ?? ''}';
        final guardian = personByContact.putIfAbsent(
          key,
          () => _newPerson(name: recipientName, phone: phone, now: now),
        );
        if (!personRecords.any((value) => value.id == guardian.id)) {
          personRecords.add(guardian);
        }
        guardianId = guardian.id;
      }
      participantRecords.add(
        Participant(
          id: participantId,
          eventId: eventId,
          personId: person.id,
          isActive: row['isActive'] as bool? ?? true,
          guardianPersonId: guardianId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final groupRecords = <Group>[];
    final groupNames = <String>{};
    for (final row in groupRows) {
      final groupName = normalizePersonText(row['name'] as String? ?? '');
      if (groupName.isEmpty) continue;
      if (!groupNames.add(groupName.toLowerCase())) {
        throw const FormatException('Há nomes de grupos repetidos.');
      }
      final sourceMembers = (row['participantIds'] as List? ?? const [])
          .whereType<String>();
      final members = sourceMembers
          .map((id) => participantIdBySourceId[id])
          .whereType<String>()
          .toList(growable: false);
      groupRecords.add(
        Group(
          id: _newId(),
          eventId: eventId,
          name: groupName,
          type: GroupTypeLabel.fromStorage(row['type'] as String?),
          restrictionEnabled:
              row['restrictionEnabled'] as bool? ??
              row['isEnabled'] as bool? ??
              true,
          memberParticipantIds: members,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _database.transaction((txn) async {
      await eventsStore.record(eventId).put(txn, event.toMap());
      for (final person in personRecords) {
        await peopleStore.record(person.id).put(txn, person.toMap());
      }
      for (final participant in participantRecords) {
        await participantsStore
            .record(participant.id)
            .put(txn, participant.toMap());
      }
      for (final group in groupRecords) {
        await groupsStore.record(group.id).put(txn, group.toMap());
      }
    });
    return eventId;
  }

  Person _newPerson({
    required String name,
    String? phone,
    required DateTime now,
  }) {
    return Person(
      id: _newId(),
      name: name,
      nickname: null,
      phoneE164: phone,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool _contactMatchesSelf(Map<String, Object?> row, String name) {
    final recipientName = normalizePersonText(
      row['recipientName'] as String? ?? '',
    );
    return recipientName.isEmpty ||
        recipientName.toLowerCase() == name.toLowerCase();
  }

  String? _optionalPhone(String? value) {
    final phone = value?.trim();
    if (phone == null || phone.isEmpty) return null;
    if (!isValidE164(phone)) {
      throw const FormatException('Um telefone do rascunho online é inválido.');
    }
    return phone;
  }

  static String _uuid() => const Uuid().v4();
}
