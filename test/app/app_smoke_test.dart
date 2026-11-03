import 'package:amigo_secreto/app/app.dart';
import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    final rawDatabase = await databaseFactoryMemory.openDatabase(
      'app_smoke_test.db',
    );
    database = AppDatabase(rawDatabase);
    await database.initialize();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('mostra o estado vazio e navega para configurações', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const AmigoSecretoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amigo Secreto'), findsOneWidget);
    expect(find.text('Nenhum evento por aqui'), findsOneWidget);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Seus dados ficam neste navegador'), findsOneWidget);
  });

  testWidgets('usa navegação inferior em tela compacta', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const AmigoSecretoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Nenhum evento por aqui'), findsOneWidget);
  });
}
