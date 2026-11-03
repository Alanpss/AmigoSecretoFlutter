import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/errors/domain_exceptions.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/groups/data/group_repository.dart';
import 'package:amigo_secreto/features/groups/domain/group.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late EventRepository events;
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

  test('cria grupo com membros e incrementa revisão', () async {
    final event = await events.create(name: 'Evento');
    final first = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana',
    );
    final second = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Bruno',
    );

    final group = await groups.create(
      eventId: event.id,
      name: '  Família   Silva ',
      type: GroupType.family,
      memberParticipantIds: {first.id, second.id},
    );

    expect(group.name, 'Família Silva');
    expect(group.restrictionEnabled, isTrue);
    expect(group.memberParticipantIds, hasLength(2));

    final stored = await groups.getById(group.id);
    expect(stored!.memberParticipantIds, containsAll([first.id, second.id]));
    expect(
      (await events.getById(event.id))!.pairingRevision,
      greaterThanOrEqualTo(3),
    );
  });

  test('bloqueia nome repetido ignorando maiúsculas e minúsculas', () async {
    final event = await events.create(name: 'Evento');
    await groups.create(
      eventId: event.id,
      name: 'Família Silva',
      type: GroupType.family,
    );

    await expectLater(
      groups.create(
        eventId: event.id,
        name: 'família silva',
        type: GroupType.family,
      ),
      throwsA(isA<DuplicateGroupNameException>()),
    );
  });

  test('bloqueia membro de outro evento', () async {
    final firstEvent = await events.create(name: 'Primeiro');
    final secondEvent = await events.create(name: 'Segundo');
    final outsider = await participants.createWithNewPerson(
      eventId: secondEvent.id,
      name: 'Ana',
    );

    await expectLater(
      groups.create(
        eventId: firstEvent.id,
        name: 'Família',
        type: GroupType.family,
        memberParticipantIds: {outsider.id},
      ),
      throwsA(isA<InvalidGroupMemberException>()),
    );
  });

  test('atualiza membros e restrição incrementando revisão', () async {
    final event = await events.create(name: 'Evento');
    final participant = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana',
    );
    final group = await groups.create(
      eventId: event.id,
      name: 'Casal',
      type: GroupType.couple,
    );
    final revisionBefore = (await events.getById(event.id))!.pairingRevision;

    final updated = await groups.update(
      id: group.id,
      name: 'Casal Ana e Bruno',
      type: GroupType.couple,
      restrictionEnabled: false,
      memberParticipantIds: {participant.id},
    );

    expect(updated.name, 'Casal Ana e Bruno');
    expect(updated.restrictionEnabled, isFalse);
    expect(updated.memberParticipantIds, [participant.id]);
    expect(
      (await events.getById(event.id))!.pairingRevision,
      revisionBefore + 1,
    );
  });

  test('exclui grupo e incrementa revisão', () async {
    final event = await events.create(name: 'Evento');
    final group = await groups.create(
      eventId: event.id,
      name: 'Outro',
      type: GroupType.other,
    );
    final revisionBefore = (await events.getById(event.id))!.pairingRevision;

    await groups.delete(group.id);

    expect(await groups.getById(group.id), isNull);
    expect(
      (await events.getById(event.id))!.pairingRevision,
      revisionBefore + 1,
    );
  });
}
