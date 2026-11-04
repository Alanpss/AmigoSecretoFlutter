import 'package:amigo_secreto/core/errors/domain_exceptions.dart';
import 'package:amigo_secreto/features/delivery/domain/whatsapp_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'remove o mais e codifica acentos, emoji, quebras e caracteres especiais',
    () {
      const message = 'Olá, Ana! 🎁\nA & B? #segredo';
      final uri = WhatsAppLink.create(
        phoneE164: '+5511900000001',
        message: message,
      )!;

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/5511900000001');
      expect(uri.queryParameters['text'], message);
    },
  );

  test('não cria link quando não há telefone', () {
    expect(
      WhatsAppLink.create(phoneE164: null, message: 'Mensagem fictícia'),
      isNull,
    );
  });

  test('rejeita valor que não esteja em E.164', () {
    expect(
      () => WhatsAppLink.create(
        phoneE164: '(11) 90000-0001',
        message: 'Mensagem fictícia',
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
