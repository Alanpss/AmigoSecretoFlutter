import 'dart:math';

import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/draw/data/draw_records.dart';
import 'package:amigo_secreto/features/draw/data/draw_repository.dart';
import 'package:amigo_secreto/features/draw/domain/draw_engine.dart';
import 'package:amigo_secreto/features/draw/domain/draw_models.dart';
import 'package:amigo_secreto/features/draw/presentation/draw_page.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/participants/data/participant_view.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:amigo_secreto/features/participants/data/person_repository.dart';
import 'package:amigo_secreto/features/participants/domain/participant.dart';
import 'package:amigo_secreto/features/participants/domain/person.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late String eventId;
  late Map<String, String> nameByParticipantId;
  late Map<String, String> assignment;

  setUp(() async {
    database = await createTestDatabase();
    final events = EventRepository(database.database);
    final participants = ParticipantRepository(database.database);
    final people = PersonRepository(database.database);
    final draws = DrawRepository(database.database);

    final event = await events.create(name: 'Encontro de teste');
    eventId = event.id;
    nameByParticipantId = {};
    for (final name in ['Ana Exemplo', 'Beto Exemplo', 'Cris Exemplo']) {
      final participant = await participants.createWithNewPerson(
        eventId: event.id,
        name: name,
      );
      nameByParticipantId[participant.id] = (await people.getById(
        participant.personId,
      ))!.name;
    }

    final preparation = await draws.prepare(event.id);
    assignment = const DrawEngine()
        .draw(preparation.request, random: Random(42))
        .assignments;
    await draws.saveDraw(
      eventId: event.id,
      drawId: 'draw-widget-test',
      pairingRevision: preparation.pairingRevision,
      pairing: assignment,
    );
  });

  tearDown(() => database.close());

  testWidgets('mantém os resultados ocultos e revela somente o selecionado', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpDrawPage(tester, database, eventId);

    expect(find.text('Proteja uma cópia do sorteio'), findsOneWidget);
    expect(find.text('Abrir backup'), findsOneWidget);
    expect(find.text('Resultado oculto'), findsNWidgets(3));

    final firstGiverId = assignment.keys.first;
    final firstGiverName = nameByParticipantId[firstGiverId]!;
    final receiverName = nameByParticipantId[assignment[firstGiverId]]!;
    final revealLabel = 'Revelar resultado de $firstGiverName';
    final giverCard = find.ancestor(
      of: find.text(firstGiverName),
      matching: find.byType(Card),
    );
    final revealButton = find.descendant(
      of: giverCard.first,
      matching: find.byTooltip(revealLabel),
    );

    expect(
      tester
          .getSemantics(
            find.descendant(
              of: giverCard.first,
              matching: find.byType(IconButton),
            ),
          )
          .label,
      revealLabel,
    );
    await tester.tap(revealButton);
    await tester.pump();

    expect(
      find.descendant(
        of: giverCard.first,
        matching: find.text('Resultado: $receiverName'),
      ),
      findsOneWidget,
    );
    expect(find.text('Resultado oculto'), findsNWidgets(2));
    expect(
      find.byTooltip('Ocultar resultado de $firstGiverName'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'preserva controles acessíveis em tela compacta com texto ampliado',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: DrawPage(eventId: eventId)),
          ),
        ),
      );
      await pumpUntil(tester, find.text('Resultado do sorteio'));

      final firstGiverName = nameByParticipantId[assignment.keys.first]!;
      final revealButton = find.byTooltip(
        'Revelar resultado de $firstGiverName',
      );
      final buttonSize = tester.getSize(revealButton);

      expect(buttonSize.width, greaterThanOrEqualTo(48));
      expect(buttonSize.height, greaterThanOrEqualTo(48));
      expect(
        tester
            .getSize(find.widgetWithText(FilledButton, 'Invalidar sorteio'))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(find.text('Invalidar sorteio'), findsOneWidget);
      expect(find.text('Abrir backup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mostra o nome do participante sem opção válida', (tester) async {
    final now = DateTime.utc(2026, 11, 3);
    const names = {
      'ana': 'Ana Exemplo',
      'bia': 'Beto Exemplo',
      'cris': 'Cris Exemplo',
    };
    final views = [
      for (final entry in names.entries)
        ParticipantWithPerson(
          participant: Participant(
            id: entry.key,
            eventId: 'event-diagnostics',
            personId: 'person-${entry.key}',
            isActive: true,
            guardianPersonId: null,
            createdAt: now,
            updatedAt: now,
          ),
          person: Person(
            id: 'person-${entry.key}',
            name: entry.value,
            nickname: null,
            phoneE164: null,
            createdAt: now,
            updatedAt: now,
          ),
          guardian: null,
          groups: const [],
        ),
    ];
    final preparation = DrawPreparation(
      eventId: 'event-diagnostics',
      pairingRevision: 0,
      hasActiveDraw: false,
      request: const DrawRequest(
        participantIds: ['ana', 'bia', 'cris'],
        groups: [
          DrawGroupConstraint(
            id: 'ana-bia',
            name: 'Grupo Ana e Beto',
            participantIds: {'ana', 'bia'},
            isEnabled: true,
          ),
          DrawGroupConstraint(
            id: 'ana-cris',
            name: 'Grupo Ana e Cris',
            participantIds: {'ana', 'cris'},
            isEnabled: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawPreparationProvider('event-diagnostics')
              .overrideWith((ref) async => preparation),
          participantsProvider('event-diagnostics')
              .overrideWith((ref) async => views),
          activeDrawProvider('event-diagnostics')
              .overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DrawPage(eventId: 'event-diagnostics')),
        ),
      ),
    );
    await pumpUntil(tester, find.text('Sortear amigo secreto'));

    expect(
      find.text('Participantes sem opção válida: Ana Exemplo'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDrawPage(
  WidgetTester tester,
  AppDatabase database,
  String eventId,
) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        home: Scaffold(body: DrawPage(eventId: eventId)),
      ),
    ),
  );
  await pumpUntil(tester, find.text('Resultado do sorteio'));
}

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Elemento não encontrado após 30 frames: $finder');
}
