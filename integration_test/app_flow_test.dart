import 'package:amigo_secreto/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Dados fictícios usados apenas neste teste.
const String eventName = 'Evento de integração';
const String participantName = 'Ana Teste';
const String participantPhone = '(11) 90000-0001';
const String groupName = 'Família Teste';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fluxo completo: evento, participante e grupo', (tester) async {
    app.main();
    await _pumpUntilFound(tester, find.text('Amigo Secreto'));

    // Evento já pode existir se a suíte rodou antes no mesmo perfil.
    if (find.text(eventName).evaluate().isEmpty) {
      await tester.tap(find.text('Criar primeiro evento'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do evento'),
        eventName,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await _pumpUntilFound(tester, find.text('Participantes ativos'));

      // Participante
      final rail = find.byType(NavigationRail);
      await tester.tap(
        find.descendant(of: rail, matching: find.text('Participantes')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Adicionar participante'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        participantName,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone (opcional)'),
        participantPhone,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Adicionar participante'),
      );
      await tester.pumpAndSettle();

      expect(find.text(participantName), findsOneWidget);

      // Grupo
      await tester.tap(
        find.descendant(of: rail, matching: find.text('Grupos')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do grupo'),
        groupName,
      );
      await tester.tap(find.text(participantName));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar grupo'));
      await tester.pumpAndSettle();

      expect(find.text(groupName), findsWidgets);
      expect(find.textContaining('1 membro'), findsOneWidget);
    }

    // Revisão
    final railAfter = find.byType(NavigationRail);
    await tester.tap(
      find.descendant(of: railAfter, matching: find.text('Revisão')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Participantes ativos insuficientes'), findsOneWidget);
  });

  testWidgets('os dados persistem ao reabrir o aplicativo', (tester) async {
    // Fecha a árvore atual e reabre o app para garantir leitura do IndexedDB.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    app.main();
    await _pumpUntilFound(tester, find.text(eventName));

    // Abre o evento pela lista de eventos.
    await tester.tap(find.text(eventName));
    await tester.pumpAndSettle();

    final rail = find.byType(NavigationRail);
    await tester.tap(
      find.descendant(of: rail, matching: find.text('Participantes')),
    );
    await tester.pumpAndSettle();

    expect(find.text(participantName), findsOneWidget);

    await tester.tap(find.descendant(of: rail, matching: find.text('Grupos')));
    await tester.pumpAndSettle();

    expect(find.text(groupName), findsWidgets);
  });
}

/// Bombeia frames até o alvo aparecer ou esgotar as tentativas.
Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Elemento não encontrado: $finder');
}
