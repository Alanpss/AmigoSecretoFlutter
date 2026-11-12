import 'dart:convert';
import 'dart:io';

import 'package:online_draw_server/online_draw_server.dart';
import 'package:test/test.dart';

void main() {
  late _MemoryStore store;
  late OnlineDrawService service;
  late OnlineDrawHttpServer server;
  late Uri baseUri;

  setUp(() async {
    store = _MemoryStore();
    var token = 0;
    service = OnlineDrawService(
      store: store,
      publicBaseUrl: 'https://draw.example',
      tokenFactory: () => 'test-token-${++token}'.padRight(40, 'x'),
    );
    server = OnlineDrawHttpServer(
      OnlineDrawApi(
        service: service,
        store: store,
        authenticator: _FakeAuthenticator(),
      ),
    );
    baseUri = await server.start(port: 0);
  });

  tearDown(() => server.close());

  test(
    'autentica organizador e nunca devolve destinatários do sorteio',
    () async {
      final client = HttpClient();
      final response = await _post(
        client,
        baseUri.resolve('/v1/events/event-a/draw'),
        {
          'pairingRevision': 2,
          'participants': [
            {'id': 'p1', 'name': 'Pessoa A', 'recipientName': 'Pessoa A'},
            {'id': 'p2', 'name': 'Pessoa B', 'recipientName': 'Responsável B'},
          ],
          'groups': [],
        },
        token: 'valid',
      );
      expect(response.statusCode, HttpStatus.created);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data.keys, {'links'});
      expect(data.toString(), isNot(contains('receiverName')));
      expect(data.toString(), isNot(contains('assignments')));
      expect(data['links'], hasLength(2));
      final noAuth = await _post(
        client,
        baseUri.resolve('/v1/events/event-b/draw'),
        {'pairingRevision': 1, 'participants': [], 'groups': []},
      );
      expect(noAuth.statusCode, HttpStatus.unauthorized);
      client.close(force: true);
    },
  );

  test(
    'revelação retorna só um resultado e revogação exige posse do evento',
    () async {
      final client = HttpClient();
      final created = await _post(
        client,
        baseUri.resolve('/v1/events/event-b/draw'),
        {
          'pairingRevision': 1,
          'participants': [
            {'id': 'p1', 'name': 'Pessoa A', 'recipientName': 'Pessoa A'},
            {'id': 'p2', 'name': 'Pessoa B', 'recipientName': 'Pessoa B'},
          ],
          'groups': [],
        },
        token: 'valid',
      );
      final links =
          (jsonDecode(created.body) as Map<String, dynamic>)['links'] as List;
      final link = links.first as Map<String, dynamic>;
      final token = Uri.parse(link['url'] as String).fragment.split('/').last;
      final reveal = await _post(client, baseUri.resolve('/v1/reveal'), {
        'token': token,
      });
      expect(reveal.statusCode, HttpStatus.ok);
      final result = jsonDecode(reveal.body) as Map<String, dynamic>;
      expect(result.keys, {'participantName', 'receiverName'});
      final forbidden = await _delete(
        client,
        baseUri.resolve('/v1/events/event-b/links/$token'),
        token: 'other',
      );
      expect(forbidden.statusCode, HttpStatus.forbidden);
      final revoked = await _delete(
        client,
        baseUri.resolve('/v1/events/event-b/links/$token'),
        token: 'valid',
      );
      expect(revoked.statusCode, HttpStatus.ok);
      final invalid = await _post(client, baseUri.resolve('/v1/reveal'), {
        'token': token,
      });
      expect(invalid.statusCode, HttpStatus.notFound);
      client.close(force: true);
    },
  );
}

Future<_Response> _post(
  HttpClient client,
  Uri uri,
  Object body, {
  String? token,
}) async {
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  if (token != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
  request.write(jsonEncode(body));
  return _read(await request.close());
}

Future<_Response> _delete(
  HttpClient client,
  Uri uri, {
  required String token,
}) async {
  final request = await client.deleteUrl(uri);
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  return _read(await request.close());
}

Future<_Response> _read(HttpClientResponse response) async => _Response(
  response.statusCode,
  await response.transform(utf8.decoder).join(),
);

class _Response {
  const _Response(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

class _FakeAuthenticator implements OrganizerAuthenticator {
  @override
  Future<String?> authenticate(String? bearerToken) async =>
      switch (bearerToken) {
        'valid' => 'owner-1',
        'other' => 'owner-2',
        _ => null,
      };
}

class _MemoryStore implements OnlineDrawStore {
  final Map<String, String> owners = {};
  final Map<String, StoredDrawResult> results = {};

  @override
  Future<bool> claimEvent({
    required String eventId,
    required String ownerUid,
  }) async {
    final owner = owners.putIfAbsent(eventId, () => ownerUid);
    return owner == ownerUid;
  }

  @override
  Future<bool> isEventOwnedBy({
    required String eventId,
    required String ownerUid,
  }) async => owners[eventId] == ownerUid;

  @override
  Future<void> saveDraw({
    required String eventId,
    required int pairingRevision,
    required Map<String, StoredDrawResult> resultsByTokenHash,
  }) async {
    results.addAll(resultsByTokenHash);
  }

  @override
  Future<StoredDrawResult?> findResultByTokenHash(String tokenHash) async =>
      results[tokenHash];

  @override
  Future<void> revokeToken(String tokenHash) async => results.remove(tokenHash);
}
