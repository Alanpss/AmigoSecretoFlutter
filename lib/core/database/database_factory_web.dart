import 'package:sembast_web/sembast_web.dart';

/// Abre o banco no IndexedDB da origem atual.
///
/// A base é vinculada ao esquema, domínio e porta. Durante o desenvolvimento,
/// use sempre a mesma origem (por exemplo, `http://localhost:8080`).
Future<Database> openAppDatabase() {
  return databaseFactoryWeb.openDatabase('amigo_secreto');
}
