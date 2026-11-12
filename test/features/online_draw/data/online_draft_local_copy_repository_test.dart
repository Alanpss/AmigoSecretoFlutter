import 'dart:convert';

import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/database/stores.dart';
import 'package:amigo_secreto/features/online_draw/data/online_draft_local_copy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  var id = 0;

  setUp(() async {
    database = await createTestDatabase();
    id = 0;
  });

  tearDown(() async => database.close());

  test(
    'cria cópia local com estado, contato direto e grupos sem resultados',
    () async {
      final copy = OnlineDraftLocalCopyRepository(
        database.database,
        newId: () => 'copy-${++id}',
      );

      final eventId = await copy.createCopy({
        'eventName': 'Evento fictício online',
        'participants': [
          {
            'id': 'online-a',
            'name': 'Pessoa A',
            'recipientName': 'Responsável compartilhado',
            'recipientPhoneE164': '+5511999990001',
            'isActive': true,
          },
          {
            'id': 'online-b',
            'name': 'Pessoa B',
            'recipientName': 'Responsável compartilhado',
            'recipientPhoneE164': '+5511999990001',
            'isActive': false,
          },
        ],
        'groups': [
          {
            'id': 'group-fake',
            'name': 'Família fictícia',
            'type': 'family',
            'restrictionEnabled': false,
            'participantIds': ['online-a', 'online-b'],
          },
        ],
        'links': [
          {'url': 'https://example.test/#/reveal/fake-token'},
        ],
        'assignments': [
          {'giverId': 'online-a', 'receiverId': 'online-b'},
        ],
      });

      final event = await eventsStore.record(eventId).get(database.database);
      final people = await peopleStore.find(database.database);
      final participants = await participantsStore.find(database.database);
      final groups = await groupsStore.find(database.database);
      final draws = await drawsStore.find(database.database);
      final assignments = await assignmentsStore.find(database.database);

      expect(event?['activeDrawId'], isNull);
      expect(event?['pairingRevision'], 0);
      expect(participants, hasLength(2));
      expect(participants.map((record) => record.value['isActive']), [
        true,
        false,
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.value['restrictionEnabled'], isFalse);
      expect(groups.single.value['memberParticipantIds'], hasLength(2));
      expect(
        people,
        hasLength(3),
        reason: 'o destinatário repetido é copiado uma vez',
      );
      expect(draws, isEmpty);
      expect(assignments, isEmpty);
      expect(
        jsonEncode({
          'event': event,
          'people': [for (final record in people) record.value],
          'participants': [for (final record in participants) record.value],
          'groups': [for (final record in groups) record.value],
        }),
        isNot(contains('fake-token')),
      );
    },
  );

  test('dados inválidos não deixam evento parcial', () async {
    final copy = OnlineDraftLocalCopyRepository(database.database);

    await expectLater(
      copy.createCopy({
        'eventName': 'Evento inválido',
        'participants': [
          {
            'id': 'online-a',
            'name': 'Pessoa A',
            'recipientName': 'Responsável',
            'recipientPhoneE164': 'telefone inválido',
          },
        ],
      }),
      throwsFormatException,
    );
    expect(await eventsStore.count(database.database), 0);
    expect(await peopleStore.count(database.database), 0);
  });
}
