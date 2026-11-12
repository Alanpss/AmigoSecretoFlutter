import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:online_draw_server/online_draw_server.dart';
import 'package:test/test.dart';

void main() {
  test('usa caminhos REST do Firestore, identidade de serviço e commit atômico', () async {
    final requests = <String>[];
    final server = await HttpServer.bind('127.0.0.1', 0);
    final completer = Completer<Map<String, dynamic>>();
    server.listen((request) async {
      requests.add(
        '${request.method} ${request.uri.path}${request.uri.hasQuery ? '?${request.uri.query}' : ''}',
      );
      final bodyText = await utf8.decoder.bind(request).join();
      if (request.uri.queryParameters['documentId'] == 'event-x') {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('{}');
      } else if (request.method == 'GET' &&
          request.uri.path.endsWith('/events/event-x')) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write(
            jsonEncode({
              'updateTime': '2026-11-05T12:00:00Z',
              'fields': {
                'ownerUid': {'stringValue': 'owner-1'},
                'pairingRevision': {'integerValue': '0'},
              },
            }),
          );
      } else if (request.uri.path.endsWith('/documents:commit')) {
        completer.complete(jsonDecode(bodyText) as Map<String, dynamic>);
        request.response
          ..statusCode = HttpStatus.ok
          ..write('{}');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final store = FirestoreOnlineDrawStore(
      projectId: 'demo-project',
      accessTokenProvider: () async => 'service-token',
      emulatorHost: '127.0.0.1:${server.port}',
    );
    expect(
      await store.claimEvent(eventId: 'event-x', ownerUid: 'owner-1'),
      isTrue,
    );
    await store.saveDraw(
      eventId: 'event-x',
      pairingRevision: 1,
      resultsByTokenHash: const {
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa':
            StoredDrawResult(
              eventId: 'event-x',
              pairingRevision: 1,
              participantId: 'p1',
              participantName: 'Pessoa A',
              receiverName: 'Pessoa B',
            ),
      },
    );

    final commit = await completer.future;
    expect(requests.first, contains('/documents/events?documentId=event-x'));
    expect(requests.last, contains('/documents:commit'));
    expect(commit['writes'], hasLength(2));
    expect(jsonEncode(commit), contains('Pessoa B'));
    expect(requests, hasLength(3));
    store.close();
  });
}
