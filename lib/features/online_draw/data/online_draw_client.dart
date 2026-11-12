import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class OnlineLink {
  const OnlineLink({
    required this.participantId,
    required this.participantName,
    required this.recipientName,
    required this.recipientPhoneE164,
    required this.url,
  });

  final String participantId;
  final String participantName;
  final String recipientName;
  final String? recipientPhoneE164;
  final String url;
}

class OnlineResult {
  const OnlineResult({
    required this.participantName,
    required this.receiverName,
  });
  final String participantName;
  final String receiverName;
}

class OnlineDrawClient {
  OnlineDrawClient({
    required this.apiBaseUrl,
    required this.auth,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiBaseUrl;
  final FirebaseAuth auth;
  final http.Client _http;

  Future<List<OnlineLink>> createDraw({
    required String eventId,
    required List<Map<String, Object?>> participants,
    required List<Map<String, Object?>> groups,
    required int pairingRevision,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw const OnlineDrawAuthenticationException();
    final String? token;
    try {
      token = await user.getIdToken();
    } catch (_) {
      throw const OnlineDrawAuthenticationException();
    }
    if (token == null || token.isEmpty) {
      throw const OnlineDrawAuthenticationException();
    }
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(
              '$apiBaseUrl/v1/events/${Uri.encodeComponent(eventId)}/draw',
            ),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'pairingRevision': pairingRevision,
              'participants': participants,
              'groups': groups,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const OnlineDrawServiceUnavailableException();
    } catch (_) {
      throw const OnlineDrawServiceUnavailableException();
    }
    if (response.statusCode == 422) {
      final error = jsonDecode(response.body);
      if (error is Map<String, dynamic> &&
          error['error'] == 'draw_impossible') {
        throw const OnlineDrawImpossibleClientException();
      }
    }
    if (response.statusCode == 400) {
      throw const OnlineDrawInvalidDataException();
    }
    if (response.statusCode == 401) {
      throw const OnlineDrawAuthenticationException();
    }
    if (response.statusCode == 403) {
      throw const OnlineDrawAccessException();
    }
    if (response.statusCode == 409) {
      throw const OnlineDrawConflictException();
    }
    if (response.statusCode >= 500) {
      throw const OnlineDrawServerException();
    }
    if (response.statusCode != 201) {
      throw const OnlineDrawClientException();
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['links'] is! List) {
      throw const OnlineDrawClientException();
    }
    return [
      for (final value in data['links'] as List)
        if (value is Map<String, dynamic>)
          OnlineLink(
            participantId: value['participantId'] as String,
            participantName: value['participantName'] as String,
            recipientName: value['recipientName'] as String,
            recipientPhoneE164: value['recipientPhoneE164'] as String?,
            url: value['url'] as String,
          )
        else
          throw const OnlineDrawClientException(),
    ];
  }

  Future<OnlineResult?> reveal(String token) async {
    final response = await _http
        .post(
          Uri.parse('$apiBaseUrl/v1/reveal'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'token': token}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw const OnlineDrawClientException();
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic> ||
        value['participantName'] is! String ||
        value['receiverName'] is! String) {
      throw const OnlineDrawClientException();
    }
    return OnlineResult(
      participantName: value['participantName'] as String,
      receiverName: value['receiverName'] as String,
    );
  }

  Future<void> revoke({required String eventId, required String token}) async {
    final user = auth.currentUser;
    if (user == null) throw const OnlineDrawClientException();
    final idToken = await user.getIdToken();
    final response = await _http.delete(
      Uri.parse(
        '$apiBaseUrl/v1/events/${Uri.encodeComponent(eventId)}/links/${Uri.encodeComponent(token)}',
      ),
      headers: {'authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) throw const OnlineDrawClientException();
  }

  Future<void> deleteEvent({required String eventId}) async {
    final user = auth.currentUser;
    if (user == null) throw const OnlineDrawAuthenticationException();
    final String? idToken;
    try {
      idToken = await user.getIdToken();
    } catch (_) {
      throw const OnlineDrawAuthenticationException();
    }
    if (idToken == null || idToken.isEmpty) {
      throw const OnlineDrawAuthenticationException();
    }
    final http.Response response;
    try {
      response = await _http
          .delete(
            Uri.parse('$apiBaseUrl/v1/events/${Uri.encodeComponent(eventId)}'),
            headers: {'authorization': 'Bearer $idToken'},
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const OnlineDrawServiceUnavailableException();
    } catch (_) {
      throw const OnlineDrawServiceUnavailableException();
    }
    if (response.statusCode == 401) {
      throw const OnlineDrawAuthenticationException();
    }
    if (response.statusCode == 403) {
      throw const OnlineDrawAccessException();
    }
    if (response.statusCode >= 500) {
      throw const OnlineDrawServerException();
    }
    if (response.statusCode != 200) throw const OnlineDrawClientException();
  }
}

class OnlineDrawClientException implements Exception {
  const OnlineDrawClientException();
}

class OnlineDrawImpossibleClientException implements Exception {
  const OnlineDrawImpossibleClientException();
}

class OnlineDrawServiceUnavailableException implements Exception {
  const OnlineDrawServiceUnavailableException();
}

class OnlineDrawAuthenticationException implements Exception {
  const OnlineDrawAuthenticationException();
}

class OnlineDrawAccessException implements Exception {
  const OnlineDrawAccessException();
}

class OnlineDrawConflictException implements Exception {
  const OnlineDrawConflictException();
}

class OnlineDrawInvalidDataException implements Exception {
  const OnlineDrawInvalidDataException();
}

class OnlineDrawServerException implements Exception {
  const OnlineDrawServerException();
}
