import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:online_draw_server/online_draw_server.dart';
import 'package:test/test.dart';

final _emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];

void main() {
  group(
    'Firestore Emulator integration',
    () {
      late FirestoreOnlineDrawStore store;
      late http.Client anonymousClient;
      final projectId =
          Platform.environment['GOOGLE_CLOUD_PROJECT'] ?? 'demo-amigosecreto';
      final emulatorHost = _emulatorHost;

      setUp(() {
        store = FirestoreOnlineDrawStore(
          projectId: projectId,
          emulatorHost: emulatorHost!,
          accessTokenProvider: () async => 'owner',
        );
        anonymousClient = http.Client();
      });

      tearDown(() {
        store.close();
        anonymousClient.close();
      });

      test('regras negam leitura e escrita anônimas', () async {
        final documentsUri = Uri.parse(
          'http://$emulatorHost/v1/projects/$projectId'
          '/databases/(default)/documents/events',
        );
        final read = await anonymousClient.get(documentsUri);
        final write = await anonymousClient.post(
          documentsUri.replace(queryParameters: {'documentId': 'anonymous'}),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'ownerUid': {'stringValue': 'anonymous'},
            },
          }),
        );

        expect(read.statusCode, 403);
        expect(write.statusCode, 403);
      });

      test('grava e recupera 200 resultados no mesmo evento', () async {
        final eventId = _uniqueId('batch');
        expect(
          await store.claimEvent(eventId: eventId, ownerUid: 'owner'),
          isTrue,
        );

        final results = _results(eventId, 'batch', 200, 1);
        await store.saveDraw(
          eventId: eventId,
          pairingRevision: 1,
          resultsByTokenHash: results,
        );

        for (final entry in results.entries) {
          _expectStoredResult(
            await store.findResultByTokenHash(entry.key),
            entry.value,
          );
        }
      });

      test(
        'conflito concorrente aceita apenas uma revisão e permite a próxima',
        () async {
          final eventId = _uniqueId('race');
          expect(
            await store.claimEvent(eventId: eventId, ownerUid: 'owner'),
            isTrue,
          );
          final initialResults = _results(eventId, 'initial', 2, 1);
          await store.saveDraw(
            eventId: eventId,
            pairingRevision: 1,
            resultsByTokenHash: initialResults,
          );

          final leftResults = _results(eventId, 'left', 2, 2);
          final rightResults = _results(eventId, 'right', 2, 2);
          final attempts = await Future.wait([
            _captureSave(store, eventId, leftResults),
            _captureSave(store, eventId, rightResults),
          ]);
          expect(attempts.where((result) => result == null).length, 1);
          final conflict = attempts.whereType<Object>().single;
          expect(
            conflict,
            anyOf(isA<StateError>(), isA<OnlineDrawConflictException>()),
          );

          final nextRevision = _results(eventId, 'next', 2, 3);
          await store.saveDraw(
            eventId: eventId,
            pairingRevision: 3,
            resultsByTokenHash: nextRevision,
          );
          for (final entry in nextRevision.entries) {
            _expectStoredResult(
              await store.findResultByTokenHash(entry.key),
              entry.value,
            );
          }
          for (final hash in [
            ...initialResults.keys,
            ...leftResults.keys,
            ...rightResults.keys,
          ]) {
            expect(await store.findResultByTokenHash(hash), isNull);
          }
        },
      );
    },
    skip: _emulatorHost == null
        ? 'Defina FIRESTORE_EMULATOR_HOST para executar os testes de integração.'
        : false,
  );
}

Future<Object?> _captureSave(
  FirestoreOnlineDrawStore store,
  String eventId,
  Map<String, StoredDrawResult> results,
) async {
  try {
    await store.saveDraw(
      eventId: eventId,
      pairingRevision: 2,
      resultsByTokenHash: results,
    );
    return null;
  } catch (error) {
    return error;
  }
}

Map<String, StoredDrawResult> _results(
  String eventId,
  String batch,
  int count,
  int revision,
) => {
  for (var index = 0; index < count; index++)
    _hash('$eventId-$batch-$index'): StoredDrawResult(
      eventId: eventId,
      pairingRevision: revision,
      participantId: 'participant-$index',
      participantName: 'Participante $index',
      receiverName: 'Destinatário $index',
    ),
};

String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

void _expectStoredResult(StoredDrawResult? actual, StoredDrawResult expected) {
  expect(actual, isNotNull);
  expect(actual!.eventId, expected.eventId);
  expect(actual.pairingRevision, expected.pairingRevision);
  expect(actual.participantId, expected.participantId);
  expect(actual.participantName, expected.participantName);
  expect(actual.receiverName, expected.receiverName);
}

String _uniqueId(String suffix) =>
    'test-$suffix-${DateTime.now().microsecondsSinceEpoch}';
