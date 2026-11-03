import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Resultado da interpretação de um telefone digitado.
class ParsedPhone {
  const ParsedPhone._({this.e164, this.error});

  const ParsedPhone.valid(String value) : this._(e164: value);
  const ParsedPhone.invalid(String message) : this._(error: message);

  final String? e164;
  final String? error;

  bool get isValid => e164 != null;
}

/// Valida e normaliza um telefone para E.164.
///
/// Regras (RN-10):
/// - entrada vazia é aceita pelo chamador como "sem telefone";
/// - sem `+`, o número é interpretado como Brasil;
/// - com `+`, o país é detectado pelo próprio número;
/// - o resultado é `+<país><número>`, somente dígitos após o `+`.
ParsedPhone parsePhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const ParsedPhone.valid('');
  }

  try {
    final parsed = trimmed.startsWith('+')
        ? PhoneNumber.parse(trimmed)
        : PhoneNumber.parse(trimmed, destinationCountry: IsoCode.BR);

    if (!parsed.isValid()) {
      return const ParsedPhone.invalid(
        'Informe um telefone válido, com DDD e número.',
      );
    }

    return ParsedPhone.valid(parsed.international);
  } on PhoneNumberException {
    return const ParsedPhone.invalid(
      'Informe um telefone válido, com DDD e número.',
    );
  } on FormatException {
    return const ParsedPhone.invalid(
      'Informe um telefone válido, com DDD e número.',
    );
  }
}

/// Verifica se um valor já armazenado está no formato E.164.
bool isValidE164(String? value) {
  if (value == null) {
    return true;
  }
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);
}
