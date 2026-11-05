import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:draw_engine/draw_engine.dart';

typedef DrawTokenFactory = String Function();

class OnlineParticipant {
  const OnlineParticipant({
    required this.id,
    required this.name,
    required this.recipientName,
    required this.recipientPhoneE164,
  });

  final String id;
  final String name;
  final String recipientName;
  final String? recipientPhoneE164;
}

class OrganizerDrawLink {
  const OrganizerDrawLink({
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

class RevealedDrawResult {
  const RevealedDrawResult({
    required this.participantName,
    required this.receiverName,
  });

  final String participantName;
  final String receiverName;
}

class StoredDrawResult {
  const StoredDrawResult({
    required this.eventId,
    required this.pairingRevision,
    required this.participantId,
    required this.participantName,
    required this.receiverName,
  });

  final String eventId;
  final int pairingRevision;
  final String participantId;
  final String participantName;
  final String receiverName;
}

abstract interface class OnlineDrawStore {
  Future<void> saveDraw({
    required String eventId,
    required int pairingRevision,
    required Map<String, StoredDrawResult> resultsByTokenHash,
  });

  Future<StoredDrawResult?> findResultByTokenHash(String tokenHash);

  Future<void> revokeToken(String tokenHash);
}

/// Generates and persists a complete draw without returning pairings to the
/// organizer-facing layer. Only the raw bearer token is included in each URL;
/// storage receives its SHA-256 digest.
class OnlineDrawService {
  factory OnlineDrawService({
    required OnlineDrawStore store,
    required String publicBaseUrl,
    DrawEngine engine = const DrawEngine(),
    DrawTokenFactory? tokenFactory,
  }) => OnlineDrawService._(
    store,
    _validateBaseUrl(publicBaseUrl),
    engine,
    tokenFactory ?? _secureToken,
  );

  OnlineDrawService._(
    this._store,
    this._publicBaseUrl,
    this._engine,
    this._tokenFactory,
  );

  final OnlineDrawStore _store;
  final String _publicBaseUrl;
  final DrawEngine _engine;
  final DrawTokenFactory _tokenFactory;

  Future<List<OrganizerDrawLink>> createDraw({
    required String eventId,
    required int pairingRevision,
    required DrawRequest request,
    required List<OnlineParticipant> participants,
  }) async {
    final participantsById = {
      for (final person in participants) person.id: person,
    };
    if (participantsById.length != participants.length ||
        participantsById.length != request.participantIds.length ||
        !participantsById.keys.toSet().containsAll(request.participantIds)) {
      throw const FormatException(
        'Os participantes do sorteio são inconsistentes.',
      );
    }

    final draw = _engine.draw(request);
    if (!draw.isPossible) {
      throw const OnlineDrawImpossibleException();
    }

    final links = <OrganizerDrawLink>[];
    final resultsByTokenHash = <String, StoredDrawResult>{};
    final usedTokenHashes = <String>{};
    for (final participant in participants) {
      final token = _tokenFactory();
      if (token.length < 32) {
        throw StateError('O gerador de links produziu um token inseguro.');
      }
      final tokenHash = sha256.convert(utf8.encode(token)).toString();
      if (!usedTokenHashes.add(tokenHash)) {
        throw StateError('O gerador de links produziu tokens repetidos.');
      }

      final receiver = participantsById[draw.assignments[participant.id]]!;
      resultsByTokenHash[tokenHash] = StoredDrawResult(
        eventId: eventId,
        pairingRevision: pairingRevision,
        participantId: participant.id,
        participantName: participant.name,
        receiverName: receiver.name,
      );
      links.add(
        OrganizerDrawLink(
          participantId: participant.id,
          participantName: participant.name,
          recipientName: participant.recipientName,
          recipientPhoneE164: participant.recipientPhoneE164,
          url: '$_publicBaseUrl/#/reveal/${Uri.encodeComponent(token)}',
        ),
      );
    }

    await _store.saveDraw(
      eventId: eventId,
      pairingRevision: pairingRevision,
      resultsByTokenHash: resultsByTokenHash,
    );
    return List.unmodifiable(links);
  }

  Future<RevealedDrawResult?> reveal(String token) async {
    if (token.length < 32) return null;
    final stored = await _store.findResultByTokenHash(
      sha256.convert(utf8.encode(token)).toString(),
    );
    if (stored == null) return null;
    return RevealedDrawResult(
      participantName: stored.participantName,
      receiverName: stored.receiverName,
    );
  }

  Future<void> revoke(String token) async {
    if (token.length < 32) return;
    await _store.revokeToken(sha256.convert(utf8.encode(token)).toString());
  }

  static String _secureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _validateBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(
        value,
        'publicBaseUrl',
        'Informe uma URL base válida.',
      );
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }
}

class OnlineDrawImpossibleException implements Exception {
  const OnlineDrawImpossibleException();
}
