import 'package:amigo_secreto/app/app.dart';
import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
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
  }

  Future<void> openSection(WidgetTester tester, String label) async {
    final rail = find.byType(NavigationRail);
    if (rail.evaluate().isNotEmpty) {
      await tester.tap(find.descendant(of: rail, matching: find.text(label)));
    } else {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('cria evento, participante e grupo pelo fluxo da interface', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Criar primeiro evento'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do evento'),
      'Amigo secreto da família',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    expect(find.text('Amigo secreto da família'), findsWidgets);
    expect(find.text('Participantes ativos'), findsOneWidget);

    await openSection(tester, 'Participantes');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Adicionar participante'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Ana Souza',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefone (opcional)'),
      '(11) 90000-0001',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Adicionar participante'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Souza'), findsOneWidget);

    await openSection(tester, 'Grupos');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do grupo'),
      'Família Souza',
    );
    await tester.tap(find.text('Ana Souza'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Família Souza'), findsWidgets);
    expect(find.textContaining('1 membro'), findsOneWidget);
  });

  testWidgets('criar grupo inline preserva os dados do participante', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Criar primeiro evento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do evento'),
      'Encontro de inverno',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    await openSection(tester, 'Participantes');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Adicionar participante'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Carla Mendes',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Apelido (opcional)'),
      'Cacá',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefone (opcional)'),
      '(21) 90000-0003',
    );

    final createGroupButton = find.widgetWithText(TextButton, 'Criar grupo');
    await tester.ensureVisible(createGroupButton);
    await tester.tap(createGroupButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do grupo'),
      'Amigos do bairro',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Nome completo'),
          )
          .controller!
          .text,
      'Carla Mendes',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Apelido (opcional)'),
          )
          .controller!
          .text,
      'Cacá',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Telefone (opcional)'),
          )
          .controller!
          .text,
      '(21) 90000-0003',
    );

    final addParticipantButton = find.widgetWithText(
      FilledButton,
      'Adicionar participante',
    );
    await tester.ensureVisible(addParticipantButton);
    await tester.tap(addParticipantButton);
    await tester.pumpAndSettle();

    expect(find.text('Carla Mendes'), findsOneWidget);
    await openSection(tester, 'Grupos');
    expect(find.text('Amigos do bairro'), findsWidgets);
    expect(find.textContaining('1 membro'), findsOneWidget);
  });
}
