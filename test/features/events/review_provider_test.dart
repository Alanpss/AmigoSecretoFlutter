import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/groups/data/group_repository.dart';
import 'package:amigo_secreto/features/groups/domain/group.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('revisão conta ativos, contatos pendentes e grupos pequenos', () async {
    final events = EventRepository(database.database);
    final participants = ParticipantRepository(database.database);
    final groups = GroupRepository(database.database);

    final event = await events.create(name: 'Evento');
    final ana = await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Ana',
      phoneE164: '+5511900000001',
    );
    await participants.createWithNewPerson(eventId: event.id, name: 'Bruno');
    await participants.createWithNewPerson(
      eventId: event.id,
      name: 'Carla',
      isActive: false,
    );
    await groups.create(
      eventId: event.id,
      name: 'Família',
      type: GroupType.family,
      memberParticipantIds: {ana.id},
    );

    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );

    final summary = await container.read(reviewProvider(event.id).future);

    expect(summary.totalParticipants, 3);
    expect(summary.activeParticipants, 2);
    expect(summary.inactiveParticipants, 1);
    expect(summary.groups, hasLength(1));
    expect(summary.restrictedGroups, 1);
    expect(summary.activeWithoutContact, hasLength(1));
    expect(summary.activeWithoutContact.single.person.name, 'Bruno');
    expect(summary.groupsWithFewMembers.single.name, 'Família');
    expect(summary.hasEnoughActiveParticipants, isTrue);
    expect(summary.hasPendingIssues, isTrue);
  });
}
