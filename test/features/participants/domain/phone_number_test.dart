import 'package:amigo_secreto/features/participants/domain/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza telefone brasileiro sem código do país', () {
    final result = parsePhoneNumber('(11) 90000-0001');

    expect(result.isValid, isTrue);
    expect(result.e164, '+5511900000001');
  });

  test('aceita telefone internacional quando começa com +', () {
    final result = parsePhoneNumber('+1 202 555 0100');

    expect(result.isValid, isTrue);
    expect(result.e164, '+12025550100');
  });

  test('entrada vazia é válida e representa ausência de telefone', () {
    final result = parsePhoneNumber('   ');

    expect(result.isValid, isTrue);
    expect(result.e164, isEmpty);
  });

  test('rejeita texto e números incompletos', () {
    expect(parsePhoneNumber('abc').isValid, isFalse);
    expect(parsePhoneNumber('123').isValid, isFalse);
  });

  test('valida o formato E.164 armazenado', () {
    expect(isValidE164(null), isTrue);
    expect(isValidE164('+5511900000001'), isTrue);
    expect(isValidE164('11900000001'), isFalse);
    expect(isValidE164('+55 11 90000-0001'), isFalse);
  });
}
