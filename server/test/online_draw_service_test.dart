import 'package:online_draw_server/online_draw_server.dart';
import 'package:draw_engine/draw_engine.dart';
import 'package:test/test.dart';

void main() {
  group('OnlineDrawService', () {
    late _MemoryOnlineDrawStore store;

    setUp(() {
      store = _MemoryOnlineDrawStore();
    });

    test(
      'organizador recebe links e cada token revela somente seu resultado',
      () async {
        var tokenIndex = 0;
        final service = OnlineDrawService(
          store: store,
          publicBaseUrl: 'https://test.example',
          tokenFactory: () => 'fake-token-${++tokenIndex}'.padRight(40, 'x'),
        );

        final links = await service.createDraw(
          eventId: 'event-1',
          pairingRevision: 3,
          request: const DrawRequest(
            participantIds: ['p1', 'p2', 'p3'],
            groups: [],
          ),
          participants: const [
            OnlineParticipant(
              id: 'p1',
              name: 'Pessoa A',
              recipientName: 'Pessoa A',
              recipientPhoneE164: '+12025550101',
            ),
            OnlineParticipant(
              id: 'p2',
              name: 'Pessoa B',
              recipientName: 'Pessoa B',
              recipientPhoneE164: null,
            ),
            OnlineParticipant(
              id: 'p3',
              name: 'Pessoa C',
              recipientName: 'Responsável C',
              recipientPhoneE164: '+12025550103',
            ),
          ],
        );

        expect(links, hasLength(3));
        expect(links.map((link) => link.participantName), contains('Pessoa A'));
        expect(links.first.url, startsWith('https://test.example/#/reveal/'));
        expect(store.lastSavedResults, hasLength(3));

        final revealed = <String>{};
        for (final link in links) {
          final token = Uri.parse(link.url).fragment.split('/').last;
          final result = await service.reveal(token);
          expect(result, isNotNull);
          expect(result!.participantName, link.participantName);
          expect(result.receiverName, isNot(link.participantName));
          revealed.add(result.receiverName);
        }
        expect(revealed, hasLength(3));
      },
    );

    test('token inválido e token revogado não revelam resultado', () async {
      var tokenIndex = 0;
      final service = OnlineDrawService(
        store: store,
        publicBaseUrl: 'https://test.example',
        tokenFactory: () => 'revocable-token-${++tokenIndex}'.padRight(40, 'x'),
      );
      final links = await service.createDraw(
        eventId: 'event-2',
        pairingRevision: 1,
        request: const DrawRequest(participantIds: ['p1', 'p2'], groups: []),
        participants: const [
          OnlineParticipant(
            id: 'p1',
            name: 'Pessoa A',
            recipientName: 'Pessoa A',
            recipientPhoneE164: null,
          ),
          OnlineParticipant(
            id: 'p2',
            name: 'Pessoa B',
            recipientName: 'Pessoa B',
            recipientPhoneE164: null,
          ),
        ],
      );
      final token = Uri.parse(links.first.url).fragment.split('/').last;

      expect(await service.reveal('invalid'), isNull);
      expect(await service.reveal('z' * 40), isNull);
      await service.revoke(token);
      expect(await service.reveal(token), isNull);
    });
  });
}

class _MemoryOnlineDrawStore implements OnlineDrawStore {
  Map<String, StoredDrawResult> lastSavedResults = {};
  final Map<String, StoredDrawResult> _results = {};

  @override
  Future<void> saveDraw({
    required String eventId,
    required int pairingRevision,
    required Map<String, StoredDrawResult> resultsByTokenHash,
  }) async {
    lastSavedResults = Map.of(resultsByTokenHash);
    _results.addAll(resultsByTokenHash);
  }

  @override
  Future<StoredDrawResult?> findResultByTokenHash(String tokenHash) async {
    return _results[tokenHash];
  }

  @override
  Future<void> revokeToken(String tokenHash) async {
    _results.remove(tokenHash);
  }
}
