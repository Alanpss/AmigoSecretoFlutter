import 'dart:convert';

import 'package:http/http.dart' as http;

import 'online_draw_api.dart';

/// Verifies client Firebase ID tokens against the Firebase Authentication
/// account lookup endpoint. The returned localId is the trusted organizer UID.
class FirebaseIdTokenAuthenticator implements OrganizerAuthenticator {
  FirebaseIdTokenAuthenticator({
    required this.webApiKey,
    http.Client? client,
    Uri? endpoint,
  }) : _client = client ?? http.Client(),
       _endpoint =
           endpoint ??
           Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:lookup');

  final String webApiKey;
  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<String?> authenticate(String? bearerToken) async {
    if (bearerToken == null || bearerToken.length > 8192 || webApiKey.isEmpty) {
      return null;
    }
    try {
      final uri = _endpoint.replace(queryParameters: {'key': webApiKey});
      final response = await _client
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'idToken': bearerToken}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['users'] is! List) return null;
      final users = body['users'] as List;
      if (users.length != 1 || users.single is! Map<String, dynamic>) {
        return null;
      }
      final uid = (users.single as Map<String, dynamic>)['localId'];
      return uid is String && uid.isNotEmpty && uid.length <= 128 ? uid : null;
    } catch (_) {
      return null;
    }
  }
}
