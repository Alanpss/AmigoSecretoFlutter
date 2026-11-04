import 'dart:typed_data';

import 'package:amigo_secreto/app/bootstrap.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('mostra uma mensagem segura quando o banco falha', (
    tester,
  ) async {
    await tester.pumpWidget(const DatabaseFailureApp());

    expect(find.text('Não foi possível abrir os dados'), findsOneWidget);
    expect(find.textContaining('Nada foi apagado'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Restaurar backup'), findsOneWidget);
  });

  testWidgets('permite tentar novamente', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(home: DatabaseFailurePage(onRetry: () => retries++)),
    );

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('restaura backup confirmado e tenta abrir novamente', (
    tester,
  ) async {
    final source = await tester.runAsync(() => _openDatabase('restore-source'));
    final target = await tester.runAsync(() => _openDatabase('restore-target'));
    await tester.runAsync(
      () => EventRepository(source!.database).create(name: 'Evento restaurado'),
    );
    final bytes = await tester.runAsync(
      () => BackupService(source!.database).exportBytes(),
    );
    await tester.runAsync(() => source!.close());

    final files = _FakeBackupFileService(bytes!);
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DatabaseFailurePage(
          onRetry: () => retries++,
          backupFileService: files,
          databaseOpener: () async => target!.database,
        ),
      ),
    );

    await tester.tap(find.text('Restaurar backup'));
    await tester.pump();
    expect(find.text('Restaurar este backup?'), findsOneWidget);
    expect(find.text('Eventos: 1'), findsOneWidget);

    await tester.tap(find.text('Importar e substituir'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.textContaining('Não foi possível restaurar o backup'),
      findsNothing,
    );
    expect(retries, 1);
  });
}

Future<AppDatabase> _openDatabase(String name) async {
  final database = AppDatabase(await databaseFactoryMemory.openDatabase(name));
  await database.initialize();
  return database;
}

class _FakeBackupFileService implements BackupFileService {
  _FakeBackupFileService(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> pick({required int maxBytes}) async => bytes;

  @override
  Future<BackupSaveResult> save({
    required String fileName,
    required Uint8List bytes,
  }) async => BackupSaveResult.saved;
}
