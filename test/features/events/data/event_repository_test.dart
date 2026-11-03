import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/events/domain/event.dart';
import 'package:amigo_secreto/features/groups/data/group_repository.dart';
import 'package:amigo_secreto/features/groups/domain/group.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:amigo_secreto/features/participants/data/person_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late EventRepository events;
  late PersonRepository people;
  late ParticipantRepository participants;
  late GroupRepository groups;
  late DateTime now;
  int sequence = 0;

  setUp(() async {
    database = await createTestDatabase();
    now = DateTime.utc(2026, 1, 1, 12);
    sequence = 0;

    String nextId(String prefix) => '$prefix-${++sequence}';

    events = EventRepository(
      database.database,
      now: () => now,
      newId: () => nextId('event'),
    );
    people = PersonRepository(
      database.database,
      now: () => now,
      newId: () => nextId('person'),
    );
    participants = ParticipantRepository(
      database.database,
      now: () => now,
      newId: () => nextId('participant'),
    );
    groups = GroupRepository(
      database.database,
      now: () => now,
      newId: () => nextId('group'),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('cria evento normalizando nome e usando modelo padrão', () async {
    final event = await events.create(name: '  Festa   da firma  ');

    expect(event.name, 'Festa da firma');
    expect(event.status, EventStatus.draft);
    expect(event.defaultCountryCode, 'BR');
    expect(event.messageTemplate, defaultMessageTemplate);

    final stored = await events.getById(event.id);
    expect(stored, isNotNull);
    expect(stored!.name, 'Festa da firma');
  });

  test('atualiza data sem horário e modelo de mensagem', () async {
    final event = await events.create(name: 'Evento');

    await events.update(
      id: event.id,
      name: 'Evento de Natal',
      eventDate: DateTime(2026, 12, 24, 21, 30),
      messageTemplate: 'Olá, {participante}!',
    );

    final updated = await events.getById(event.id);
    expect(updated!.name, 'Evento de Natal');
    expect(updated.eventDate, DateTime(2026, 12, 24));
    expect(updated.messageTemplate, 'Olá, {participante}!');
  });

  test('lista resumo com total e ativos por evento', () async {
    final event = await events.create(name: 'Evento');
    final first = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana',
    );
    await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Bruno',
      isActive: false,
    );

    final summaries = await events.listSummaries();

    expect(summaries, hasLength(1));
    expect(summaries.single.totalParticipants, 2);
    expect(summaries.single.activeParticipants, 1);
    expect(first.eventId, event.id);
  });

  test(
    'excluir evento remove participantes e grupos e preserva pessoas',
    () async {
      final event = await events.create(name: 'Evento');
      final participant = await participants.createWithNewPerson(
        eventId: event.id,
        name: 'Ana',
      );
      final group = await groups.create(
        eventId: event.id,
        name: 'Família',
        type: GroupType.family,
        memberParticipantIds: {participant.id},
      );

      await events.delete(event.id);

      expect(await events.getById(event.id), isNull);
      expect(await participants.getById(participant.id), isNull);
      expect(await groups.getById(group.id), isNull);
      expect(await people.getAll(), hasLength(1));
    },
  );
}
