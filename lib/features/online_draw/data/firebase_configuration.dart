import 'package:firebase_core/firebase_core.dart';

/// Values are supplied at build/run time and are never committed as secrets.
abstract final class FirebaseConfiguration {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty &&
      authDomain.isNotEmpty;

  static String? get configurationError {
    if (!isConfigured) {
      return 'O login online não foi configurado neste build. Configure o app Web no Firebase e gere o aplicativo com as opções FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID e FIREBASE_AUTH_DOMAIN.';
    }
    if (!useEmulators &&
        (projectId.startsWith('demo-') ||
            apiKey.startsWith('demo-') ||
            appId.startsWith('demo-') ||
            messagingSenderId.startsWith('demo-') ||
            authDomain.startsWith('demo-'))) {
      return 'Este build está usando valores Firebase de demonstração sem os emuladores. Configure um projeto Firebase real para habilitar o login Google.';
    }
    return null;
  }

  static bool get canInitialize => configurationError == null;

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? '$projectId.firebaseapp.com' : authDomain,
  );
}
