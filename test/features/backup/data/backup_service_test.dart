import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/database/stores.dart';
import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/backup/domain/backup_document.dart';
import 'package:amigo_secreto/features/draw/data/draw_repository.dart';
import 'package:amigo_secreto/features/draw/domain/draw_engine.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../support/test_database.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  late AppDatabase source;
  late AppDatabase target;

  setUp(() async {
    source = await createTestDatabase();
    target = await createTestDatabase();
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test(
    'exporta e restaura todos os dados com sorteio ativo e entregas',
    () async {
      await _seedDraw(source);
      final sourceService = BackupService(source.database, now: () => now);
      final bytes = await sourceService.exportBytes();
      final document = BackupDocument.decode(bytes);

      expect(document.preview.people, 3);
      expect(document.preview.events, 1);
      expect(document.preview.participants, 3);
      expect(document.preview.draws, 1);
      expect(document.preview.activeDraws, 1);
      expect(document.preview.deliveries, 3);
      expect(jsonDecode(utf8.decode(bytes))['schemaVersion'], 1);

      final targetEvents = EventRepository(target.database, now: () => now);
      await targetEvents.create(name: 'Evento que será substituído');
      await BackupService(target.database, now: () => now).importBytes(bytes);

      final restoredEvent = (await eventsStore.find(target.database))
          .single
          .value;
      expect(restoredEvent['activeDrawId'], 'draw-backup-test');
      expect(await peopleStore.find(target.database), hasLength(3));
      expect(await participantsStore.find(target.database), hasLength(3));
      expect(await assignmentsStore.find(target.database), hasLength(3));
      expect(await deliveriesStore.find(target.database), hasLength(3));
      expect(await drawsStore.find(target.database), hasLength(1));
    },
  );

  test(
    'backup vazio inclui estrutura completa e nome sem dado pessoal',
    () async {
      final bytes = await BackupService(
        source.database,
        now: () => now,
      ).exportBytes();
      final document = BackupDocument.decode(bytes);

      expect(document.preview.events, 0);
      expect(document.stores.keys, containsAll(backupStoreNames));
      expect(
        BackupService.fileName(now),
        'amigo-secreto-backup-2026-11-03.json',
      );
    },
  );

  test('rejeita versão futura, loja ausente e referência quebrada', () async {
    await _seedDraw(source);
    final service = BackupService(source.database, now: () => now);
    final validBytes = await service.exportBytes();

    final futureVersion = _mutablePayload(validBytes)
      ..['schemaVersion'] = currentBackupSchemaVersion + 1;
    expect(
      () => BackupDocument.decode(_encode(futureVersion)),
      throwsA(isA<BackupFormatException>()),
    );

    final missingStore = _mutablePayload(validBytes)
      ..['stores'].remove('settings');
    expect(
      () => BackupDocument.decode(_encode(missingStore)),
      throwsA(isA<BackupFormatException>()),
    );

    final missingField = _mutablePayload(validBytes);
    final missingFieldParticipants =
        missingField['stores']['participants'] as List<dynamic>;
    missingFieldParticipants.first['value'].remove('eventId');
    expect(
      () => BackupDocument.decode(_encode(missingField)),
      throwsA(isA<BackupFormatException>()),
    );

    final brokenReference = _mutablePayload(validBytes);
    final participantEntries =
        brokenReference['stores']['participants'] as List<dynamic>;
    participantEntries.first['value']['personId'] = 'person-inexistente';
    expect(
      () => BackupDocument.decode(_encode(brokenReference)),
      throwsA(isA<BackupFormatException>()),
    );
    final preservedEvent = await EventRepository(target.database)
        .create(name: 'Evento preservado');
    await expectLater(
      BackupService(target.database).importBytes(_encode(brokenReference)),
      throwsA(isA<BackupFormatException>()),
    );
    final unchanged = await eventsStore.find(target.database);
    expect(unchanged, hasLength(1));
    expect(unchanged.single.key, preservedEvent.id);
    expect(
      () => BackupDocument.decode(Uint8List.fromList(utf8.encode('{'))),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => BackupDocument.decode(Uint8List(maxBackupBytes + 1)),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('falha durante a transação mantém a base anterior intacta', () async {
    await _seedDraw(source);
    final bytes = await BackupService(
      source.database,
      now: () => now,
    ).exportBytes();
    final oldEvent = await EventRepository(target.database)
        .create(name: 'Evento preservado');
    final failingService = BackupService(
      target.database,
      now: () => now,
      beforeStoreWrite: (storeName) {
        if (storeName == 'assignments') {
          throw StateError('Falha de teste');
        }
      },
    );

    await expectLater(failingService.importBytes(bytes), throwsStateError);

    final remainingEvents = await eventsStore.find(target.database);
    expect(remainingEvents, hasLength(1));
    expect(remainingEvents.single.key, oldEvent.id);
    expect(await peopleStore.find(target.database), isEmpty);
  });
}

Future<void> _seedDraw(AppDatabase database) async {
  var sequence = 0;
  String nextId() => 'record-${++sequence}';
  final events = EventRepository(database.database, newId: nextId);
  final participants = ParticipantRepository(database.database, newId: nextId);
  final draws = DrawRepository(database.database, newId: nextId);
  final event = await events.create(name: 'Encontro fictício');
  for (final name in ['Ana Exemplo', 'Beto Exemplo', 'Cris Exemplo']) {
    await participants.createWithNewPerson(eventId: event.id, name: name);
  }
  final preparation = await draws.prepare(event.id);
  final result = const DrawEngine().draw(
    preparation.request,
    random: Random(7),
  );
  await draws.saveDraw(
    eventId: event.id,
    drawId: 'draw-backup-test',
    pairingRevision: preparation.pairingRevision,
    pairing: result.assignments,
  );
}

Map<String, dynamic> _mutablePayload(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

Uint8List _encode(Map<String, dynamic> payload) =>
    Uint8List.fromList(utf8.encode(jsonEncode(payload)));
