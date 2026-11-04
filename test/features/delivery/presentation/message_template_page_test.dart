import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/delivery/presentation/message_template_page.dart';
import 'package:amigo_secreto/features/events/domain/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() => database.close());

  testWidgets(
    'não salva modelo com sorteio ativo se não conseguiu carregar entregas',
    (tester) async {
      final event = Event(
        id: 'event-1',
        name: 'Encontro fictício',
        eventDate: null,
        defaultCountryCode: 'BR',
        messageTemplate: 'Mensagem para {participante}',
        activeDrawId: 'draw-1',
        pairingRevision: 1,
        createdAt: DateTime.utc(2026, 11, 3),
        updatedAt: DateTime.utc(2026, 11, 3),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            eventProvider('event-1').overrideWith((ref) async => event),
            activeDeliveriesProvider('event-1').overrideWith((ref) async {
              throw StateError('Falha fictícia');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MessageTemplatePage(eventId: 'event-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível conferir as entregas.'),
        findsOneWidget,
      );
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Salvar modelo'),
      );
      expect(saveButton.onPressed, isNull);
    },
  );
}
