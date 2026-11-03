import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/errors/domain_exceptions.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
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

  test(
    'cria pessoa e participação em uma transação e incrementa revisão',
    () async {
      final event = await events.create(name: 'Evento');

      final participant = await participants.createWithNewPerson(
        eventId: event.id,
        name: '  Ana   Maria ',
        nickname: 'Aninha',
        phoneE164: '+5511900000001',
      );

      expect(participant.isActive, isTrue);
      final person = await people.getById(participant.personId);
      expect(person!.name, 'Ana Maria');
      expect(person.nickname, 'Aninha');
      expect(person.phoneE164, '+5511900000001');

      final updatedEvent = await events.getById(event.id);
      expect(updatedEvent!.pairingRevision, 1);
    },
  );

  test('bloqueia a mesma pessoa duas vezes no mesmo evento', () async {
    final event = await events.create(name: 'Evento');
    final participant = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana',
    );

    await expectLater(
      participants.createWithExistingPerson(
        eventId: event.id,
        personId: participant.personId,
      ),
      throwsA(isA<DuplicateParticipationException>()),
    );
  });

  test('aceita a mesma pessoa em eventos diferentes', () async {
    final firstEvent = await events.create(name: 'Primeiro');
    final secondEvent = await events.create(name: 'Segundo');
    final participant = await participants.createWithNewPerson(
      eventId: firstEvent.id,
      name: 'Ana',
    );

    final second = await participants.createWithExistingPerson(
      eventId: secondEvent.id,
      personId: participant.personId,
    );

    expect(second.personId, participant.personId);
    expect(second.eventId, secondEvent.id);
  });

  test('encontra nome e telefone duplicados sem bloquear o cadastro', () async {
    await people.create(name: 'Ana Souza', phoneE164: '+5511900000001');
    await people.create(name: '  ana   souza ', phoneE164: '+5511900000001');

    final matches = await people.findMatches(
      name: 'ANA SOUZA',
      phoneE164: '+5511900000001',
    );

    expect(matches.nameMatches, hasLength(2));
    expect(matches.phoneMatches, hasLength(2));
  });

  test('responsável não pode ser o próprio participante', () async {
    final event = await events.create(name: 'Evento');
    final person = await people.create(name: 'Ana');

    await expectLater(
      participants.createWithExistingPerson(
        eventId: event.id,
        personId: person.id,
        guardianPersonId: person.id,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('atualiza pessoa, responsável e grupos na mesma transação', () async {
    final event = await events.create(name: 'Evento');
    final guardian = await people.create(name: 'Mãe');
    final participant = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Filho',
    );
    final group = await groups.create(
      eventId: event.id,
      name: 'Família',
      type: GroupType.family,
    );

    final updated = await participants.updateParticipant(
      participantId: participant.id,
      name: 'Filho Atualizado',
      nickname: 'Filhote',
      phoneE164: '+5511900000002',
      guardianPersonId: guardian.id,
      isActive: false,
      groupIds: {group.id},
    );

    expect(updated.guardianPersonId, guardian.id);
    expect(updated.isActive, isFalse);

    final person = await people.getById(participant.personId);
    expect(person!.name, 'Filho Atualizado');
    expect(person.nickname, 'Filhote');
    expect(person.phoneE164, '+5511900000002');

    final storedGroup = await groups.getById(group.id);
    expect(storedGroup!.memberParticipantIds, contains(participant.id));

    final updatedEvent = await events.getById(event.id);
    expect(updatedEvent!.pairingRevision, greaterThanOrEqualTo(2));
  });

  test('remover participação limpa grupos e preserva a pessoa', () async {
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

    await participants.delete(participant.id);

    expect(await participants.getById(participant.id), isNull);
    expect(await people.getById(participant.personId), isNotNull);
    final storedGroup = await groups.getById(group.id);
    expect(storedGroup!.memberParticipantIds, isEmpty);
  });

  test('editar pessoa em um evento incrementa revisão dos demais', () async {
    final firstEvent = await events.create(name: 'Primeiro');
    final secondEvent = await events.create(name: 'Segundo');
    final participant = await participants.createWithNewPerson(
      eventId: firstEvent.id,
      name: 'Ana',
    );
    await participants.createWithExistingPerson(
      eventId: secondEvent.id,
      personId: participant.personId,
    );

    await people.update(
      id: participant.personId,
      name: 'Ana Paula',
      phoneE164: '+5511900000001',
    );

    final first = await events.getById(firstEvent.id);
    final second = await events.getById(secondEvent.id);
    expect(first!.pairingRevision, greaterThanOrEqualTo(2));
    expect(second!.pairingRevision, greaterThanOrEqualTo(2));
  });
}
