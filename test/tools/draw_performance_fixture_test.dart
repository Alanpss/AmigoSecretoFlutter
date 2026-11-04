import 'dart:io';

import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/backup/domain/backup_document.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test('gera backup temporário com 200 participantes fictícios', () async {
    final rawDatabase = await databaseFactoryMemory.openDatabase(
      'draw_performance_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final database = AppDatabase(rawDatabase);
    try {
      await database.initialize();
      final event = await EventRepository(rawDatabase)
          .create(name: 'Evento fictício para teste de desempenho');
      final participants = ParticipantRepository(rawDatabase);
      for (var index = 1; index <= 200; index++) {
        await participants.createWithNewPerson(
          eventId: event.id,
          name: 'Pessoa de teste ${index.toString().padLeft(3, '0')}',
          phoneE164: index == 1 ? '+12025550100' : null,
        );
      }

      final bytes = await BackupService(rawDatabase).exportBytes();
      final preview = BackupDocument.decode(bytes).preview;
      expect(preview.events, 1);
      expect(preview.participants, 200);

      const fileName = 'amigo-secreto-backup-test-200.json';
      final output = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
      );
      await output.writeAsBytes(bytes, flush: true);
      // The fixture uses synthetic names and one fictional contact number.
    } finally {
      await database.close();
    }
  });
}
