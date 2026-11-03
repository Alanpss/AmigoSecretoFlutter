import 'package:sembast/sembast.dart';

/// Implementação de segurança para plataformas não suportadas.
Future<Database> openAppDatabase() {
  throw UnsupportedError(
    'O armazenamento local não está disponível nesta plataforma.',
  );
}
