import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:draw_engine/draw_engine.dart';

import 'online_draw_service.dart';

abstract interface class OrganizerAuthenticator {
  Future<String?> authenticate(String? bearerToken);
}

/// HTTP boundary. Organizer routes require an authenticated Firebase UID and
/// event ownership; reveal responses contain only the matching participant.
class OnlineDrawApi {
  OnlineDrawApi({
    required this.service,
    required this.store,
    required this.authenticator,
  });

  final OnlineDrawService service;
  final OnlineDrawStore store;
  final OrganizerAuthenticator authenticator;

  Future<void> handle(HttpRequest request) async {
    try {
      if (request.method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.noContent
          ..headers.set('access-control-allow-origin', '*')
          ..headers.set(
            'access-control-allow-methods',
            'GET, POST, DELETE, OPTIONS',
          )
          ..headers.set(
            'access-control-allow-headers',
            'authorization, content-type',
          );
        await request.response.close();
        return;
      }
      final segments = request.uri.pathSegments;
      if (request.method == 'GET' && request.uri.path == '/health') {
        _send(request, HttpStatus.ok, {'status': 'ok'});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/v1/reveal') {
        final body = await _readJson(request);
        final result = await service.reveal(_string(body, 'token'));
        if (result == null) {
          _send(request, HttpStatus.notFound, {'error': 'link_invalid'});
        } else {
          _send(request, HttpStatus.ok, {
            'participantName': result.participantName,
            'receiverName': result.receiverName,
          });
        }
        return;
      }

      final ownerUid = await authenticator.authenticate(
        _bearer(request.headers.value(HttpHeaders.authorizationHeader)),
      );
      if (ownerUid == null) {
        _send(request, HttpStatus.unauthorized, {
          'error': 'authentication_required',
        });
        return;
      }
      if (segments.length == 4 &&
          segments[0] == 'v1' &&
          segments[1] == 'events' &&
          segments[3] == 'draw' &&
          request.method == 'POST') {
        final eventId = segments[2];
        if (!_validId(eventId)) {
          _send(request, HttpStatus.badRequest, {'error': 'invalid_event'});
          return;
        }
        if (!await store.claimEvent(eventId: eventId, ownerUid: ownerUid)) {
          _send(request, HttpStatus.forbidden, {'error': 'event_not_owned'});
          return;
        }
        final body = await _readJson(request);
        final participants = _participants(body['participants']);
        final groups = _groups(body['groups']);
        final revision = body['pairingRevision'];
        if (revision is! int || revision < 1) {
          _send(request, HttpStatus.badRequest, {'error': 'invalid_revision'});
          return;
        }
        final links = await service.createDraw(
          eventId: eventId,
          pairingRevision: revision,
          request: DrawRequest(
            participantIds: participants
                .map((p) => p.id)
                .toList(growable: false),
            groups: groups,
          ),
          participants: participants,
        );
        // This deliberately serializes only delivery information, never pairs.
        _send(request, HttpStatus.created, {
          'links': [
            for (final link in links)
              {
                'participantId': link.participantId,
                'participantName': link.participantName,
                'recipientName': link.recipientName,
                if (link.recipientPhoneE164 != null)
                  'recipientPhoneE164': link.recipientPhoneE164,
                'url': link.url,
              },
          ],
        });
        return;
      }
      if (segments.length == 5 &&
          segments[0] == 'v1' &&
          segments[1] == 'events' &&
          segments[3] == 'links' &&
          request.method == 'DELETE') {
        final eventId = segments[2];
        if (!await store.isEventOwnedBy(eventId: eventId, ownerUid: ownerUid)) {
          _send(request, HttpStatus.forbidden, {'error': 'event_not_owned'});
          return;
        }
        final token = segments[4];
        final result = await service.reveal(token);
        if (result == null) {
          _send(request, HttpStatus.notFound, {'error': 'link_invalid'});
        } else {
          // Ensure the bearer token belongs to this event before revoking it.
          final stored = await store.findResultByTokenHash(_tokenHash(token));
          if (stored?.eventId != eventId) {
            _send(request, HttpStatus.notFound, {'error': 'link_invalid'});
          } else {
            await service.revoke(token);
            _send(request, HttpStatus.ok, {'revoked': true});
          }
        }
        return;
      }
      if (segments.length == 3 &&
          segments[0] == 'v1' &&
          segments[1] == 'events' &&
          request.method == 'DELETE') {
        final eventId = segments[2];
        if (!_validId(eventId)) {
          _send(request, HttpStatus.badRequest, {'error': 'invalid_event'});
          return;
        }
        final deleted = await service.deleteEvent(
          eventId: eventId,
          ownerUid: ownerUid,
        );
        if (!deleted) {
          _send(request, HttpStatus.forbidden, {'error': 'event_not_owned'});
        } else {
          _send(request, HttpStatus.ok, {'deleted': true});
        }
        return;
      }
      _send(request, HttpStatus.notFound, {'error': 'not_found'});
    } on FormatException {
      _send(request, HttpStatus.badRequest, {'error': 'invalid_request'});
    } on OnlineDrawImpossibleException {
      _send(request, HttpStatus.unprocessableEntity, {
        'error': 'draw_impossible',
      });
    } on OnlineDrawConflictException {
      _send(request, HttpStatus.conflict, {'error': 'draw_revision_conflict'});
    } catch (_) {
      // Never return exception text: it can contain personal data or tokens.
      _send(request, HttpStatus.internalServerError, {
        'error': 'internal_error',
      });
    }
  }

  static Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    if (request.contentLength > 1024 * 1024) throw const FormatException();
    final text = await utf8.decoder.bind(request).join();
    if (text.length > 1024 * 1024) throw const FormatException();
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic>) throw const FormatException();
    return value;
  }

  static List<OnlineParticipant> _participants(Object? value) {
    if (value is! List || value.length < 2 || value.length > 200) {
      throw const FormatException();
    }
    return [
      for (final item in value)
        if (item is Map<String, dynamic>)
          OnlineParticipant(
            id: _string(item, 'id'),
            name: _name(item, 'name'),
            recipientName: _name(item, 'recipientName'),
            recipientPhoneE164: _optionalPhone(item['recipientPhoneE164']),
          )
        else
          throw const FormatException(),
    ];
  }

  static List<DrawGroupConstraint> _groups(Object? value) {
    if (value is! List || value.length > 200) throw const FormatException();
    return [
      for (final item in value)
        if (item is Map<String, dynamic> &&
            item['participantIds'] is List &&
            (item['participantIds'] as List).every((id) => id is String))
          DrawGroupConstraint(
            id: _string(item, 'id'),
            name: _name(item, 'name'),
            participantIds: (item['participantIds'] as List)
                .cast<String>()
                .toSet(),
            isEnabled: item['isEnabled'] == true,
          )
        else
          throw const FormatException(),
    ];
  }

  static String _name(Map<String, dynamic> map, String key) {
    final value = _string(map, key).trim();
    if (value.isEmpty || value.length > 160) throw const FormatException();
    return value;
  }

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) throw const FormatException();
    return value;
  }

  static String? _optionalPhone(Object? value) {
    if (value == null) return null;
    if (value is! String ||
        value.length > 16 ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value)) {
      throw const FormatException();
    }
    return value;
  }

  static bool _validId(String value) =>
      value.isNotEmpty &&
      value.length <= 128 &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value);

  static String? _bearer(String? value) {
    if (value == null || !value.startsWith('Bearer ')) return null;
    final token = value.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  static String _tokenHash(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  static void _send(HttpRequest request, int status, Object body) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..headers.set('cache-control', 'no-store')
      ..headers.set('access-control-allow-origin', '*')
      ..write(jsonEncode(body));
    request.response.close();
  }
}

class OnlineDrawHttpServer {
  OnlineDrawHttpServer(this.api);
  final OnlineDrawApi api;
  HttpServer? _server;

  Future<Uri> start({String host = '127.0.0.1', int port = 8080}) async {
    _server = await HttpServer.bind(host, port);
    _server!.listen(api.handle);
    return Uri(scheme: 'http', host: host, port: _server!.port);
  }

  Future<void> close() async => _server?.close(force: true);
}
