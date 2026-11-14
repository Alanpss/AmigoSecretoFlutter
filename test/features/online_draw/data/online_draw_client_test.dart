import 'package:amigo_secreto/features/online_draw/data/online_draw_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeOnlineDrawParticipants', () {
    test('normalizes a Brazilian number with spaces and punctuation', () {
      final result = normalizeOnlineDrawParticipants([
        {
          'id': 'participant-1',
          'name': 'Pessoa Fictícia',
          'recipientName': 'Pessoa Fictícia',
          'recipientPhoneE164': '+55 (11) 99999-0001',
        },
      ]);

      expect(result.single['recipientPhoneE164'], '+5511999990001');
    });

    test('preserves a participant without a phone number', () {
      final participant = {
        'id': 'participant-1',
        'name': 'Pessoa Fictícia',
        'recipientName': 'Pessoa Fictícia',
      };

      expect(normalizeOnlineDrawParticipants([participant]), [participant]);
    });

    test('rejects a phone number that cannot be parsed', () {
      expect(
        () => normalizeOnlineDrawParticipants([
          {
            'id': 'participant-1',
            'name': 'Pessoa Fictícia',
            'recipientName': 'Pessoa Fictícia',
            'recipientPhoneE164': 'telefone inválido',
          },
        ]),
        throwsA(isA<OnlineDrawInvalidDataException>()),
      );
    });

    test('omits a blank optional phone', () {
      final result = normalizeOnlineDrawParticipants([
        {
          'id': 'participant-1',
          'name': 'Pessoa Fictícia',
          'recipientName': 'Pessoa Fictícia',
          'recipientPhoneE164': '  ',
        },
      ]);

      expect(result.single.containsKey('recipientPhoneE164'), isFalse);
    });
  });
}
