/// Formata uma data sem fuso para exibição em pt-BR.
String formatDateBr(DateTime? date) {
  if (date == null) {
    return 'Sem data';
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Formata um telefone E.164 brasileiro para leitura; outros países ficam como
/// estão.
String formatPhoneForDisplay(String? phoneE164) {
  if (phoneE164 == null || phoneE164.isEmpty) {
    return 'Sem telefone';
  }
  if (!phoneE164.startsWith('+55')) {
    return phoneE164;
  }

  final digits = phoneE164.substring(3);
  if (digits.length == 11) {
    return '+55 (${digits.substring(0, 2)}) '
        '${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '+55 (${digits.substring(0, 2)}) '
        '${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return phoneE164;
}
