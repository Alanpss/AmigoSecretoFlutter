/// Limites e validações de texto de pessoa.
const int maxPersonNameLength = 120;
const int maxNicknameLength = 40;

/// Normaliza espaços em excesso sem alterar acentos ou maiúsculas.
String normalizePersonText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Retorna uma mensagem de erro ou `null` quando o nome é válido.
String? validatePersonName(String? raw) {
  final name = normalizePersonText(raw ?? '');
  if (name.isEmpty) {
    return 'Informe o nome da pessoa.';
  }
  if (name.length > maxPersonNameLength) {
    return 'O nome deve ter no máximo $maxPersonNameLength caracteres.';
  }
  return null;
}

/// Retorna uma mensagem de erro ou `null` quando o apelido é válido.
String? validateNickname(String? raw) {
  final nickname = normalizePersonText(raw ?? '');
  if (nickname.isEmpty) {
    return null;
  }
  if (nickname.length > maxNicknameLength) {
    return 'O apelido deve ter no máximo $maxNicknameLength caracteres.';
  }
  return null;
}

/// Retorna uma mensagem de erro ou `null` quando o nome do evento é válido.
String? validateEventName(String? raw, {required int maxLength}) {
  final name = normalizePersonText(raw ?? '');
  if (name.isEmpty) {
    return 'Informe o nome do evento.';
  }
  if (name.length > maxLength) {
    return 'O nome deve ter no máximo $maxLength caracteres.';
  }
  return null;
}
