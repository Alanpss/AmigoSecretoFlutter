import 'dart:convert';

import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/online_draw/data/online_draw_draft_repository.dart';
import 'package:amigo_secreto/core/database/stores.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../support/test_database.dart';

void main() {
  test('restaura o rascunho online local sem incluí-lo no backup', () async {
    final database = await createTestDatabase();
    addTearDown(database.close);
    final drafts = OnlineDrawDraftRepository(database.database);
    const tokenUrl =
        'https://draw.example/#/reveal/fake-bearer-token-only-for-test';

    await drafts.save({
      'eventId': 'fake-event-id',
      'eventName': 'Evento de teste',
      'groupsText': '',
      'participants': [
        {'name': 'Pessoa Fictícia A', 'recipientName': 'Pessoa Fictícia A'},
      ],
      'links': [
        {'participantName': 'Pessoa Fictícia A', 'url': tokenUrl},
      ],
      'revokedUrls': <String>[],
    });

    final restored = await drafts.load();
    expect(restored?['eventName'], 'Evento de teste');
    expect(restored?['participants'], hasLength(1));
    expect(restored?['links'], hasLength(1));

    final backup = utf8.decode(
      await BackupService(database.database).exportBytes(),
    );
    expect(backup, isNot(contains('Evento de teste')));
    expect(backup, isNot(contains('fake-bearer-token')));
  });

  test(
    'mantém e carrega vários eventos online sem sobrescrever links',
    () async {
      final database = await createTestDatabase();
      addTearDown(database.close);
      final drafts = OnlineDrawDraftRepository(database.database);

      await drafts.save({
        'eventId': 'online-event-a',
        'eventName': 'Evento fictício A',
        'participants': <Object?>[],
        'links': [
          {'url': 'https://draw.example/#/reveal/fake-token-a'},
        ],
      });
      await drafts.save({
        'eventId': 'online-event-b',
        'eventName': 'Evento fictício B',
        'participants': <Object?>[],
        'links': [
          {'url': 'https://draw.example/#/reveal/fake-token-b'},
        ],
      });

      final first = await drafts.load(eventId: 'online-event-a');
      final second = await drafts.load(eventId: 'online-event-b');
      final all = await drafts.list();

      expect(all, hasLength(2));
      expect(first?['eventName'], 'Evento fictício A');
      expect(second?['eventName'], 'Evento fictício B');
      expect((first?['links'] as List).single['url'], contains('fake-token-a'));
      expect(
        (second?['links'] as List).single['url'],
        contains('fake-token-b'),
      );

      await drafts.clear(eventId: 'online-event-a');
      final remaining = await drafts.list();
      expect(remaining, hasLength(1));
      expect(remaining.single['eventId'], 'online-event-b');
    },
  );

  test('migra o antigo rascunho current sem perder links', () async {
    final database = await createTestDatabase();
    addTearDown(database.close);
    await onlineDraftsStore.record('current').put(database.database, {
      'eventId': 'legacy-online-event',
      'eventName': 'Evento legado fictício',
      'participants': <Object?>[],
      'links': [
        {'url': 'https://draw.example/#/reveal/fake-legacy-token'},
      ],
    });
    final drafts = OnlineDrawDraftRepository(database.database);

    final migrated = await drafts.load(eventId: 'legacy-online-event');
    final oldCurrent = await onlineDraftsStore
        .record('current')
        .get(database.database);
    final storedById = await onlineDraftsStore
        .record('legacy-online-event')
        .get(database.database);

    expect(migrated?['eventName'], 'Evento legado fictício');
    expect(migrated?['links'], hasLength(1));
    expect(oldCurrent, isNull);
    expect(storedById?['eventName'], 'Evento legado fictício');
  });
}
