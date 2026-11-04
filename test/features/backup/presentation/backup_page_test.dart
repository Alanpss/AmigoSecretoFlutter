import 'dart:typed_data';

import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/database/stores.dart';
import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/backup/presentation/backup_page.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late AppDatabase source;
  late _FakeBackupFileService files;

  setUp(() async {
    database = await createTestDatabase();
    source = await createTestDatabase();
    files = _FakeBackupFileService();
  });

  tearDown(() async {
    await database.close();
    await source.close();
  });

  Future<void> pumpPage(WidgetTester tester, {double textScale = 1}) async {
    final router = GoRouter(
      initialLocation: '/backup',
      routes: [
        GoRoute(
          path: '/backup',
          builder: (context, state) => const Scaffold(body: BackupPage()),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Início')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('Configurações')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          backupFileServiceProvider.overrideWithValue(files),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('exporta JSON com nome de arquivo sem dados pessoais', (
    tester,
  ) async {
    await tester.runAsync(
      () => EventRepository(database.database).create(name: 'Evento fictício'),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Exportar backup'));
    await _drainAsync(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      files.savedFileName,
      matches(RegExp(r'^amigo-secreto-backup-\d{4}-\d{2}-\d{2}\.json$')),
    );
    expect(files.savedBytes, isNotNull);
    expect(
      find.text('Backup exportado. Guarde o arquivo em local seguro.'),
      findsOneWidget,
    );
  });

  testWidgets('pré-visualiza e confirma substituição antes de importar', (
    tester,
  ) async {
    await tester.runAsync(
      () => EventRepository(source.database).create(name: 'Evento restaurado'),
    );
    files.pickedBytes = await tester.runAsync(
      () => BackupService(source.database).exportBytes(),
    );
    await tester.runAsync(
      () => EventRepository(database.database).create(name: 'Evento atual'),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Selecionar backup'));
    await _drainAsync(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Substituir os dados deste aplicativo?'), findsOneWidget);
    expect(find.text('Eventos: 1'), findsOneWidget);
    expect(
      find.textContaining('telefones e resultados de sorteios'),
      findsOneWidget,
    );

    await tester.tap(find.text('Importar e substituir'));
    await _drainAsync(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Início'), findsOneWidget);
    final restoredEvents = await tester.runAsync(
      () => eventsStore.find(database.database),
    );
    expect(restoredEvents, hasLength(1));
    expect(restoredEvents!, hasLength(1));
    expect(restoredEvents.single.value['name'], 'Evento restaurado');
  });

  testWidgets('cancelar prévia preserva os dados atuais', (tester) async {
    await tester.runAsync(
      () => EventRepository(source.database).create(name: 'Outro backup'),
    );
    files.pickedBytes = await tester.runAsync(
      () => BackupService(source.database).exportBytes(),
    );
    await tester.runAsync(
      () =>
          EventRepository(database.database).create(name: 'Evento preservado'),
    );
    await pumpPage(tester);

    await tester.tap(find.text('Selecionar backup'));
    await _drainAsync(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Cancelar'));
    await _drainAsync(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final events = await tester.runAsync(
      () => eventsStore.find(database.database),
    );
    expect(events, hasLength(1));
    expect(events!, hasLength(1));
    expect(events.single.value['name'], 'Evento preservado');
  });

  testWidgets('tela compacta suporta escala de texto 200 por cento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester, textScale: 2);

    expect(find.text('Backup e restauração'), findsOneWidget);
    expect(find.text('Exportar backup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _drainAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
}

class _FakeBackupFileService implements BackupFileService {
  Uint8List? pickedBytes;
  Uint8List? savedBytes;
  String? savedFileName;

  @override
  Future<Uint8List?> pick({required int maxBytes}) async => pickedBytes;

  @override
  Future<Uri?> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedFileName = fileName;
    savedBytes = bytes;
    return Uri.parse('memory:backup');
  }
}
