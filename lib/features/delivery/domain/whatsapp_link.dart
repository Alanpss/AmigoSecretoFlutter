import '../../../core/errors/domain_exceptions.dart';
import '../../participants/domain/phone_number.dart';

/// Cria um link click-to-chat sem abrir o WhatsApp.
abstract final class WhatsAppLink {
  static Uri? create({required String? phoneE164, required String message}) {
    if (phoneE164 == null || phoneE164.isEmpty) return null;
    if (!isValidE164(phoneE164)) {
      throw const ValidationException(
        'O telefone não está em um formato válido para abrir o WhatsApp.',
      );
    }

    final digits = phoneE164.replaceAll(RegExp(r'\D'), '');
    final encodedMessage = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$digits?text=$encodedMessage');
  }
}
