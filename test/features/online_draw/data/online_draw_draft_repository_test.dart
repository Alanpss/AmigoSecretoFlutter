import 'dart:convert';

import 'package:amigo_secreto/features/backup/data/backup_service.dart';
import 'package:amigo_secreto/features/online_draw/data/online_draw_draft_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
