import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/database/stores.dart';
import 'package:amigo_secreto/core/errors/domain_exceptions.dart';
import 'package:amigo_secreto/features/draw/data/draw_repository.dart';
import 'package:amigo_secreto/features/draw/domain/draw_engine.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/groups/data/group_repository.dart';
import 'package:amigo_secreto/features/groups/domain/group.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:amigo_secreto/features/participants/data/person_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late EventRepository events;
  late ParticipantRepository participants;
  late PersonRepository people;
  late GroupRepository groups;
  late DrawRepository draws;
  var id = 0;

  setUp(() async {
    database = await createTestDatabase();
    String nextId() => 'id-${++id}';
    events = EventRepository(database.database, newId: nextId);
    participants = ParticipantRepository(database.database, newId: nextId);
    people = PersonRepository(database.database, newId: nextId);
    groups = GroupRepository(database.database, newId: nextId);
    draws = DrawRepository(database.database, newId: nextId);
  });

  tearDown(() => database.close());

  test('salva tudo atomicamente, retorna sorteio ativo e invalida preservando histórico', () async {
    final event = await events.create(name: 'Encontro fictício');
    final a = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana Exemplo',
    );
    final b = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Beto Exemplo',
    );
    final c = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Cris Exemplo',
    );
    final d = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Dani Exemplo',
    );
    await groups.create(
      eventId: event.id,
      name: 'Equipe fictícia',
      type: GroupType.other,
      memberParticipantIds: {a.id, b.id},
    );

    final prep = await draws.prepare(event.id);
    final result = const DrawEngine().draw(prep.request);
    final saved = await draws.saveDraw(
      eventId: event.id,
      drawId: 'draw-a',
      pairingRevision: prep.pairingRevision,
      pairing: result.assignments,
    );
    final retried = await draws.saveDraw(
      eventId: event.id,
      drawId: 'draw-a',
      pairingRevision: prep.pairingRevision,
      pairing: result.assignments,
    );
    expect(
      retried.assignments.map((a) => a.id),
      saved.assignments.map((a) => a.id),
    );

    expect(saved.assignments, hasLength(4));
    expect(saved.deliveries, hasLength(4));
    expect(
      saved.deliveries.map((d) => d.ownerNameSnapshot),
      contains('Ana Exemplo'),
    );
    expect(
      saved.deliveries.every(
        (d) => d.messageSnapshot.contains('Encontro fictício'),
      ),
      isTrue,
    );
    expect((await events.getById(event.id))!.activeDrawId, 'draw-a');
    expect((await draws.getActiveDraw(event.id))!.pairing, result.assignments);
    await expectLater(
      participants.createWithNewPerson(eventId: event.id, name: 'Dani Exemplo'),
      throwsA(isA<ActiveDrawException>()),
    );
    await expectLater(
      groups.delete((await groups.getByEvent(event.id)).single.id),
      throwsA(isA<ActiveDrawException>()),
    );
    await expectLater(
      people.update(id: a.personId, name: 'Nome alterado'),
      throwsA(isA<ActiveDrawException>()),
    );

    final summary = await draws.invalidateDraw(event.id);
    expect(summary.opened, 0);
    expect(summary.confirmed, 0);
    expect((await events.getById(event.id))!.activeDrawId, isNull);
    expect((await draws.getDraw('draw-a'))!.draw.status.name, 'invalidated');
    expect(
      (await participants.getByEvent(event.id)).map((p) => p.id),
      containsAll([a.id, b.id, c.id, d.id]),
    );

    final nextPreparation = await draws.prepare(event.id);
    final nextResult = const DrawEngine().draw(nextPreparation.request);
    await expectLater(
      draws.saveDraw(
        eventId: event.id,
        drawId: 'draw-a',
        pairingRevision: nextPreparation.pairingRevision,
        pairing: nextResult.assignments,
      ),
      throwsA(isA<DrawIdConflictException>()),
    );
    await draws.saveDraw(
      eventId: event.id,
      drawId: 'draw-b',
      pairingRevision: nextPreparation.pairingRevision,
      pairing: nextResult.assignments,
    );
    expect(await draws.getDraw('draw-a'), isNotNull);
    expect((await draws.getActiveDraw(event.id))!.draw.id, 'draw-b');
  });

  test('aborta quando a revisão mudou sem gravar registros parciais', () async {
    final event = await events.create(name: 'Encontro');
    await participants.createWithNewPerson(eventId: event.id, name: 'Ana');
    await participants.createWithNewPerson(eventId: event.id, name: 'Beto');
    final prep = await draws.prepare(event.id);
    final result = const DrawEngine().draw(prep.request);
    await participants.createWithNewPerson(eventId: event.id, name: 'Cris');

    await expectLater(
      draws.saveDraw(
        eventId: event.id,
        drawId: 'draw-stale',
        pairingRevision: prep.pairingRevision,
        pairing: result.assignments,
      ),
      throwsA(isA<PairingRevisionConflictException>()),
    );
    expect(await drawsStore.find(database.database), isEmpty);
    expect(await assignmentsStore.find(database.database), isEmpty);
    expect(await deliveriesStore.find(database.database), isEmpty);
    expect((await events.getById(event.id))!.activeDrawId, isNull);
  });
}
