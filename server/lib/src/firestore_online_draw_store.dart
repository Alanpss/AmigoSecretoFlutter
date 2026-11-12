import 'dart:convert';

import 'package:http/http.dart' as http;

import 'online_draw_service.dart';

typedef FirestoreAccessTokenProvider = Future<String?> Function();

/// Uses the attached Cloud Run service identity. No service-account key is
/// stored in environment variables or the repository.
class CloudRunMetadataAccessTokenProvider {
  CloudRunMetadataAccessTokenProvider({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint =
          endpoint ??
          Uri.parse(
            'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
          );

  final http.Client _client;
  final Uri _endpoint;

  Future<String?> call() async {
    try {
      final response = await _client
          .get(_endpoint, headers: {'Metadata-Flavor': 'Google'})
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      final token = body is Map<String, dynamic> ? body['access_token'] : null;
      return token is String && token.isNotEmpty ? token : null;
    } catch (_) {
      return null;
    }
  }
}

/// Firestore REST adapter. Set [emulatorHost] for local Emulator Suite tests;
/// production requests use the Cloud Run service identity token provider.
class FirestoreOnlineDrawStore implements OnlineDrawStore {
  FirestoreOnlineDrawStore({
    required this.projectId,
    required this.accessTokenProvider,
    String? emulatorHost,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _baseUri = Uri.parse(
         '${emulatorHost == null ? 'https://firestore.googleapis.com' : 'http://$emulatorHost'}/v1',
       );

  final String projectId;
  final FirestoreAccessTokenProvider accessTokenProvider;
  final http.Client _client;
  final Uri _baseUri;

  void close() => _client.close();

  String get _root => '/projects/$projectId/databases/(default)/documents';

  @override
  Future<bool> claimEvent({
    required String eventId,
    required String ownerUid,
  }) async {
    final uri = _uri(
      '$_root/events?documentId=${Uri.encodeComponent(eventId)}',
    );
    // createDocument is atomic: a competing organizer cannot replace ownerUid.
    final response = await _request(
      'POST',
      uri,
      body: {
        'fields': {
          'ownerUid': _str(ownerUid),
          'pairingRevision': {'integerValue': '0'},
        },
      },
    );
    if (response.statusCode == 200) return true;
    if (response.statusCode != 409 && response.statusCode != 400) return false;
    final existing = await _get(
      '$_root/events/${Uri.encodeComponent(eventId)}',
    );
    return existing != null && _fieldString(existing, 'ownerUid') == ownerUid;
  }

  @override
  Future<bool> isEventOwnedBy({
    required String eventId,
    required String ownerUid,
  }) async {
    final doc = await _get('$_root/events/${Uri.encodeComponent(eventId)}');
    return doc != null && _fieldString(doc, 'ownerUid') == ownerUid;
  }

  @override
  Future<void> saveDraw({
    required String eventId,
    required int pairingRevision,
    required Map<String, StoredDrawResult> resultsByTokenHash,
  }) async {
    final owned = await _get('$_root/events/${Uri.encodeComponent(eventId)}');
    if (owned == null) throw StateError('Evento indisponível.');
    final ownerUid = _fieldString(owned, 'ownerUid');
    final previousRevisionText = _fieldString(owned, 'pairingRevision') ?? '0';
    final previousRevision = int.tryParse(previousRevisionText) ?? 0;
    final updateTime = owned['updateTime'];
    if (ownerUid == null ||
        pairingRevision != previousRevision + 1 ||
        updateTime is! String) {
      throw const OnlineDrawConflictException();
    }
    final priorHashes =
        ((owned['fields'] as Map<String, dynamic>?)?['linkHashes']
            as Map<String, dynamic>?)?['arrayValue'];
    final oldValues = priorHashes is Map<String, dynamic>
        ? priorHashes['values']
        : null;
    final oldHashes = oldValues is List
        ? oldValues
              .whereType<Map<String, dynamic>>()
              .map((value) => value['stringValue'])
              .whereType<String>()
              .toSet()
        : <String>{};
    final writes = <Map<String, Object?>>[
      for (final oldHash in oldHashes.difference(
        resultsByTokenHash.keys.toSet(),
      ))
        {
          'delete':
              'projects/$projectId/databases/(default)/documents/results/$oldHash',
        },
      {
        'update': {
          'name':
              'projects/$projectId/databases/(default)/documents/events/$eventId',
          'fields': {
            'ownerUid': {'stringValue': ownerUid},
            'pairingRevision': {'integerValue': '$pairingRevision'},
            'linkHashes': {
              'arrayValue': {
                'values': resultsByTokenHash.keys.map(_str).toList(),
              },
            },
          },
        },
        'currentDocument': {'updateTime': updateTime},
      },
      for (final entry in resultsByTokenHash.entries)
        {
          'update': {
            'name':
                'projects/$projectId/databases/(default)/documents/results/${entry.key}',
            'fields': _resultFields(entry.value),
          },
        },
    ];
    final response = await _request(
      'POST',
      _uri('$_root:commit'),
      body: {'writes': writes},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Não foi possível salvar o sorteio online.');
    }
  }

  @override
  Future<StoredDrawResult?> findResultByTokenHash(String tokenHash) async {
    final doc = await _get('$_root/results/${Uri.encodeComponent(tokenHash)}');
    if (doc == null) return null;
    final fields = doc['fields'];
    if (fields is! Map<String, dynamic>) return null;
    final eventId = _fieldString(doc, 'eventId');
    final revisionValue = _fieldString(doc, 'pairingRevision');
    final revision = revisionValue == null ? null : int.tryParse(revisionValue);
    if (eventId == null || revision == null) return null;
    return StoredDrawResult(
      eventId: eventId,
      pairingRevision: revision,
      participantId: _fieldString(doc, 'participantId') ?? '',
      participantName: _fieldString(doc, 'participantName') ?? '',
      receiverName: _fieldString(doc, 'receiverName') ?? '',
    );
  }

  @override
  Future<void> revokeToken(String tokenHash) async {
    final response = await _request(
      'DELETE',
      _uri('$_root/results/${Uri.encodeComponent(tokenHash)}'),
    );
    if (response.statusCode != 404 && response.statusCode != 200) {
      throw StateError('Não foi possível revogar o link.');
    }
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    final response = await _request('GET', _uri(path));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw StateError('Falha ao consultar o armazenamento online.');
    }
    final json = jsonDecode(response.body);
    return json is Map<String, dynamic> ? json : null;
  }

  Uri _uri(String path) => Uri.parse('$_baseUri$path');

  Future<http.Response> _request(String method, Uri uri, {Object? body}) async {
    final headers = <String, String>{'content-type': 'application/json'};
    final token = await accessTokenProvider();
    if (token != null) headers['authorization'] = 'Bearer $token';
    return switch (method) {
      'GET' =>
        _client.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
      'POST' =>
        _client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10)),
      'DELETE' =>
        _client
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 10)),
      _ => throw ArgumentError.value(method),
    };
  }

  static Map<String, Object?> _resultFields(StoredDrawResult result) => {
    'eventId': _str(result.eventId),
    'pairingRevision': {'integerValue': '${result.pairingRevision}'},
    'participantId': _str(result.participantId),
    'participantName': _str(result.participantName),
    'receiverName': _str(result.receiverName),
  };

  static Map<String, Object?> _str(String value) => {'stringValue': value};

  static String? _fieldString(Map<String, dynamic> doc, String key) {
    final fields = doc['fields'];
    final value = fields is Map<String, dynamic> ? fields[key] : null;
    if (value is! Map<String, dynamic>) return null;
    return (value['stringValue'] ?? value['integerValue'])?.toString();
  }
}
