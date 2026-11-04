import 'package:url_launcher/url_launcher.dart';

/// Borda de plataforma para abrir a conversa após ação explícita do usuário.
abstract interface class WhatsAppLauncher {
  Future<bool> open(Uri uri);
}

class UrlLauncherWhatsAppLauncher implements WhatsAppLauncher {
  const UrlLauncherWhatsAppLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
