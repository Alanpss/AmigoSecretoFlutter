import 'dart:convert';
import 'dart:typed_data';

import '../../../core/database/migrations.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../draw/data/draw_records.dart';
import '../../delivery/domain/message_template.dart';
import '../../events/domain/event.dart';
import '../../groups/domain/group.dart';
import '../../participants/domain/participant.dart';
import '../../participants/domain/person.dart';
import '../../participants/domain/phone_number.dart';

const String backupAppId = 'amigo_secreto_flutter';
const int currentBackupSchemaVersion = 1;
const int maxBackupBytes = 10 * 1024 * 1024;

const List<String> backupStoreNames = [
  'meta',
  'people',
  'events',
  'participants',
  'groups',
  'draws',
  'assignments',
  'deliveries',
  'settings',
];

/// Registro do banco serializado com a chave Sembast preservada.
class BackupEntry {
  const BackupEntry({required this.key, required this.value});

  final String key;
  final Map<String, Object?> value;

  Map<String, Object?> toJson() => {'key': key, 'value': value};
}

/// Documento validado antes de exportar ou substituir dados locais.
class BackupDocument {
  const BackupDocument({required this.exportedAt, required this.stores});

  final DateTime exportedAt;
  final Map<String, List<BackupEntry>> stores;

  BackupPreview get preview => BackupPreview(
    exportedAt: exportedAt,
    people: stores['people']!.length,
    events: stores['events']!.length,
    participants: stores['participants']!.length,
    groups: stores['groups']!.length,
    draws: stores['draws']!.length,
    deliveries: stores['deliveries']!.length,
    activeDraws: stores['events']!
        .where((entry) => entry.value['activeDrawId'] != null)
        .length,
  );

  Uint8List toBytes() {
    final json = <String, Object?>{
      'appId': backupAppId,
      'schemaVersion': currentBackupSchemaVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'databaseSchemaVersion': currentSchemaVersion,
      'stores': {
        for (final name in backupStoreNames)
          name: stores[name]!.map((entry) => entry.toJson()).toList(),
      },
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
    );
  }

  factory BackupDocument.decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const BackupFormatException('O arquivo de backup está vazio.');
    }
    if (bytes.length > maxBackupBytes) {
      throw const BackupFormatException(
        'O arquivo excede o limite de 10 MB. Escolha um backup menor.',
      );
    }

    try {
      final root = _asMap(jsonDecode(utf8.decode(bytes)));
      if (root['appId'] != backupAppId) {
        throw const BackupFormatException(
          'Este arquivo não pertence ao Amigo Secreto.',
        );
      }
      final version = root['schemaVersion'];
      if (version is! int || version != currentBackupSchemaVersion) {
        throw const BackupFormatException(
          'A versão deste backup não é compatível com o aplicativo.',
        );
      }
      final databaseVersion = root['databaseSchemaVersion'];
      if (databaseVersion is! int || databaseVersion != currentSchemaVersion) {
        throw const BackupFormatException(
          'A versão dos dados não é compatível com este aplicativo.',
        );
      }
      final exportedAt = DateTime.tryParse(root['exportedAt'] as String? ?? '');
      if (exportedAt == null) {
        throw const BackupFormatException(
          'A data de exportação do backup não é válida.',
        );
      }

      final rawStores = _asMap(root['stores']);
      if (rawStores.keys
              .toSet()
              .difference(backupStoreNames.toSet())
              .isNotEmpty ||
          !rawStores.keys.toSet().containsAll(backupStoreNames)) {
        throw const BackupFormatException(
          'O backup não contém a estrutura de dados esperada.',
        );
      }

      final stores = <String, List<BackupEntry>>{};
      for (final name in backupStoreNames) {
        final rawEntries = rawStores[name];
        if (rawEntries is! List) {
          throw const BackupFormatException(
            'A estrutura de um conjunto de dados está inválida.',
          );
        }
        final entries = <BackupEntry>[];
        final seenKeys = <String>{};
        for (final rawEntry in rawEntries) {
          final entryMap = _asMap(rawEntry);
          final key = entryMap['key'];
          if (key is! String || key.isEmpty || !seenKeys.add(key)) {
            throw const BackupFormatException(
              'O backup contém uma chave de registro inválida ou repetida.',
            );
          }
          entries.add(BackupEntry(key: key, value: _asMap(entryMap['value'])));
        }
        stores[name] = List.unmodifiable(entries);
      }

      final document = BackupDocument(
        exportedAt: exportedAt.toUtc(),
        stores: Map.unmodifiable(stores),
      );
      _validateRecords(document, databaseVersion);
      return document;
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException(
        'Não foi possível ler este backup. Confira o arquivo e tente novamente.',
      );
    }
  }
}

class BackupPreview {
  const BackupPreview({
    required this.exportedAt,
    required this.people,
    required this.events,
    required this.participants,
    required this.groups,
    required this.draws,
    required this.deliveries,
    required this.activeDraws,
  });

  final DateTime exportedAt;
  final int people;
  final int events;
  final int participants;
  final int groups;
  final int draws;
  final int deliveries;
  final int activeDraws;
}

class BackupFormatException extends ValidationException {
  const BackupFormatException(super.message);
}

Map<String, Object?> _asMap(Object? value) {
  if (value is! Map) {
    throw const BackupFormatException(
      'O formato dos dados do backup é inválido.',
    );
  }
  if (value.keys.any((key) => key is! String)) {
    throw const BackupFormatException(
      'O formato dos dados do backup é inválido.',
    );
  }
  return {for (final entry in value.entries) entry.key as String: entry.value};
}

List<T> _parseRecords<T>(
  List<BackupEntry> entries,
  T Function(Map<String, Object?> map) parse,
) {
  final result = <T>[];
  for (final entry in entries) {
    final record = parse(entry.value);
    final id = entry.value['id'];
    if (id is! String || id != entry.key) {
      throw const BackupFormatException(
        'A chave de um registro não corresponde ao seu identificador.',
      );
    }
    result.add(record);
  }
  return result;
}

void _validateRecords(BackupDocument document, int databaseVersion) {
  final meta = {
    for (final entry in document.stores['meta']!) entry.key: entry.value,
  };
  final schemaVersion = meta['schemaVersion']?['value'];
  if (schemaVersion is! int ||
      schemaVersion != databaseVersion ||
      meta['createdAt']?['value'] is! String) {
    throw const BackupFormatException(
      'Os metadados do backup estão incompletos ou incompatíveis.',
    );
  }

  final people = _parseRecords(document.stores['people']!, Person.fromMap);
  final peopleById = {for (final person in people) person.id: person};
  if (peopleById.length != people.length ||
      people.any((person) => !isValidE164(person.phoneE164))) {
    throw const BackupFormatException(
      'Há pessoas duplicadas ou com telefone inválido no backup.',
    );
  }

  final events = _parseRecords(document.stores['events']!, Event.fromMap);
  final eventsById = {for (final event in events) event.id: event};
  if (eventsById.length != events.length) {
    throw const BackupFormatException('O backup contém eventos duplicados.');
  }
  for (final event in events) {
    MessageTemplate.parse(event.messageTemplate);
  }

  final participants = _parseRecords(
    document.stores['participants']!,
    Participant.fromMap,
  );
  final participantsById = {for (final item in participants) item.id: item};
  final eventPeople = <String>{};
  for (final participant in participants) {
    if (!eventsById.containsKey(participant.eventId) ||
        !peopleById.containsKey(participant.personId) ||
        (participant.guardianPersonId != null &&
            (!peopleById.containsKey(participant.guardianPersonId) ||
                participant.guardianPersonId == participant.personId)) ||
        !eventPeople.add('${participant.eventId}:${participant.personId}')) {
      throw const BackupFormatException(
        'O backup contém uma participação ou vínculo inválido.',
      );
    }
  }

  final groups = _parseRecords(document.stores['groups']!, Group.fromMap);
  for (final group in groups) {
    final rawGroup = document.stores['groups']!
        .singleWhere((entry) => entry.key == group.id)
        .value;
    if (!eventsById.containsKey(group.eventId) ||
        !GroupType.values.any((type) => type.name == rawGroup['type']) ||
        rawGroup['restrictionEnabled'] is! bool ||
        rawGroup['memberParticipantIds'] is! List ||
        (rawGroup['memberParticipantIds'] as List).any((id) => id is! String) ||
        (rawGroup['memberParticipantIds'] as List).length !=
            group.memberParticipantIds.length ||
        group.memberParticipantIds.toSet().length !=
            group.memberParticipantIds.length ||
        group.memberParticipantIds.any((id) {
          final member = participantsById[id];
          return member == null || member.eventId != group.eventId;
        })) {
      throw const BackupFormatException(
        'O backup contém um grupo com vínculos inválidos.',
      );
    }
  }

  final draws = _parseRecords(document.stores['draws']!, DrawRecord.fromMap);
  final drawsById = {for (final draw in draws) draw.id: draw};
  final activeDrawsByEvent = <String, String>{};
  for (final draw in draws) {
    final rawDraw = document.stores['draws']!
        .singleWhere((entry) => entry.key == draw.id)
        .value;
    if (!eventsById.containsKey(draw.eventId)) {
      throw const BackupFormatException(
        'O backup contém um sorteio sem evento.',
      );
    }
    if (!PersistedDrawStatus.values.any(
      (status) => status.name == rawDraw['status'],
    )) {
      throw const BackupFormatException(
        'O backup contém um estado de sorteio inválido.',
      );
    }
    if (draw.status == PersistedDrawStatus.active) {
      if (activeDrawsByEvent.containsKey(draw.eventId)) {
        throw const BackupFormatException(
          'O backup contém mais de um sorteio ativo para um evento.',
        );
      }
      activeDrawsByEvent[draw.eventId] = draw.id;
    }
  }
  for (final event in events) {
    if (event.activeDrawId != activeDrawsByEvent[event.id]) {
      throw const BackupFormatException(
        'O sorteio ativo de um evento não corresponde aos registros do backup.',
      );
    }
  }

  final assignments = _parseRecords(
    document.stores['assignments']!,
    AssignmentRecord.fromMap,
  );
  final assignmentsById = {for (final item in assignments) item.id: item};
  final givers = <String>{};
  final receivers = <String>{};
  for (final assignment in assignments) {
    final draw = drawsById[assignment.drawId];
    final giver = participantsById[assignment.giverParticipantId];
    final receiver = participantsById[assignment.receiverParticipantId];
    if (draw == null ||
        draw.eventId != assignment.eventId ||
        (draw.status == PersistedDrawStatus.active &&
            (giver == null ||
                receiver == null ||
                giver.eventId != assignment.eventId ||
                receiver.eventId != assignment.eventId)) ||
        (giver != null && giver.eventId != assignment.eventId) ||
        (receiver != null && receiver.eventId != assignment.eventId) ||
        assignment.giverParticipantId == assignment.receiverParticipantId ||
        !givers.add('${assignment.drawId}:${assignment.giverParticipantId}') ||
        !receivers.add(
          '${assignment.drawId}:${assignment.receiverParticipantId}',
        )) {
      throw const BackupFormatException(
        'O backup contém uma atribuição de sorteio inválida.',
      );
    }
  }

  for (final draw in draws.where(
    (item) => item.status == PersistedDrawStatus.active,
  )) {
    final activeParticipantIds = participants
        .where(
          (participant) =>
              participant.eventId == draw.eventId && participant.isActive,
        )
        .map((participant) => participant.id)
        .toSet();
    final drawAssignments = assignments
        .where((assignment) => assignment.drawId == draw.id)
        .toList(growable: false);
    final drawGivers = drawAssignments
        .map((assignment) => assignment.giverParticipantId)
        .toSet();
    final drawReceivers = drawAssignments
        .map((assignment) => assignment.receiverParticipantId)
        .toSet();
    if (activeParticipantIds.length < 2 ||
        drawGivers.length != activeParticipantIds.length ||
        drawReceivers.length != activeParticipantIds.length ||
        !drawGivers.containsAll(activeParticipantIds) ||
        !drawReceivers.containsAll(activeParticipantIds)) {
      throw const BackupFormatException(
        'O sorteio ativo não contém uma atribuição completa para cada participante.',
      );
    }
  }

  final deliveries = _parseRecords(
    document.stores['deliveries']!,
    DeliveryRecord.fromMap,
  );
  final deliveriesByAssignment = <String>{};
  for (final delivery in deliveries) {
    final assignment = assignmentsById[delivery.assignmentId];
    final draw = drawsById[delivery.drawId];
    final owner = participantsById[delivery.ownerParticipantId];
    final recipient = delivery.recipientPersonId == null
        ? null
        : peopleById[delivery.recipientPersonId];
    final isActiveDraw = draw?.status == PersistedDrawStatus.active;
    if (assignment == null ||
        draw == null ||
        assignment.drawId != delivery.drawId ||
        assignment.eventId != delivery.eventId ||
        draw.eventId != delivery.eventId ||
        assignment.giverParticipantId != delivery.ownerParticipantId ||
        (isActiveDraw &&
            (owner == null ||
                owner.eventId != delivery.eventId ||
                (delivery.recipientPersonId != null && recipient == null) ||
                (delivery.recipientKind == 'self' &&
                    delivery.recipientPersonId != owner.personId) ||
                (delivery.recipientKind == 'guardian' &&
                    owner.guardianPersonId != delivery.recipientPersonId))) ||
        !isValidE164(delivery.recipientPhoneSnapshot) ||
        !['pending', 'opened', 'confirmed'].contains(delivery.status) ||
        !['self', 'guardian'].contains(delivery.recipientKind) ||
        !['whatsapp', 'manual'].contains(delivery.channel) ||
        (delivery.confirmationMethod != null &&
            !['whatsapp', 'manual'].contains(delivery.confirmationMethod)) ||
        (delivery.status == 'confirmed' &&
            (delivery.confirmedAt == null ||
                delivery.confirmationMethod == null)) ||
        (delivery.status == 'opened' && delivery.openedAt == null) ||
        delivery.channel !=
            (delivery.recipientPhoneSnapshot == null ? 'manual' : 'whatsapp') ||
        !deliveriesByAssignment.add(delivery.assignmentId)) {
      throw const BackupFormatException(
        'O backup contém uma entrega inválida.',
      );
    }
  }
  if (deliveriesByAssignment.length != assignments.length) {
    throw const BackupFormatException(
      'O backup não contém uma entrega para cada atribuição.',
    );
  }

  for (final entry in document.stores['settings']!) {
    if (entry.value.isEmpty && entry.key.isEmpty) {
      throw const BackupFormatException(
        'Uma configuração do backup é inválida.',
      );
    }
  }
}
