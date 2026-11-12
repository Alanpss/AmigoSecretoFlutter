import 'dart:io';

import 'package:online_draw_server/online_draw_server.dart';

Future<void> main() async {
  final projectId =
      Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
      Platform.environment['GCLOUD_PROJECT'];
  final webApiKey = Platform.environment['FIREBASE_WEB_API_KEY'];
  final publicBaseUrl = Platform.environment['PUBLIC_BASE_URL'];
  if (projectId == null ||
      projectId.isEmpty ||
      webApiKey == null ||
      webApiKey.isEmpty ||
      publicBaseUrl == null ||
      publicBaseUrl.isEmpty) {
    stderr.writeln(
      'Configuração obrigatória ausente (projeto, chave Firebase ou URL pública).',
    );
    exitCode = 64;
    return;
  }

  final authEmulator = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];
  final firestoreEmulator = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final authEndpoint = authEmulator == null
      ? null
      : Uri.parse(
          'http://$authEmulator/identitytoolkit.googleapis.com/v1/accounts:lookup',
        );
  final store = FirestoreOnlineDrawStore(
    projectId: projectId,
    accessTokenProvider: firestoreEmulator == null
        ? CloudRunMetadataAccessTokenProvider().call
        // The Emulator Suite's local admin auth sentinel; never used outside
        // the explicit FIRESTORE_EMULATOR_HOST configuration.
        : () async => 'owner',
    emulatorHost: firestoreEmulator,
  );
  final service = OnlineDrawService(store: store, publicBaseUrl: publicBaseUrl);
  final authenticator = FirebaseIdTokenAuthenticator(
    webApiKey: webApiKey,
    endpoint: authEndpoint,
  );
  final api = OnlineDrawApi(
    service: service,
    store: store,
    authenticator: authenticator,
  );
  final httpServer = OnlineDrawHttpServer(api);
  final address = await httpServer.start(
    host: Platform.environment['HOST'] ?? '0.0.0.0',
    port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080,
  );
  stdout.writeln('Servidor HTTP pronto em ${address.host}:${address.port}.');
}
