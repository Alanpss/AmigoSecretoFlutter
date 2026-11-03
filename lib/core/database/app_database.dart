import 'package:sembast/sembast.dart';

import '../errors/app_error.dart';
import 'database_factory.dart';
import 'migrations.dart';

/// Fachada do banco local do aplicativo.
///
/// O banco é aberto e migrado antes da interface. Em caso de falha, nada é
/// apagado automaticamente; a camada de bootstrap mostra uma tela segura.
class AppDatabase {
  AppDatabase(this.database);

  final Database database;

  bool _closed = false;

  /// Abre o banco da plataforma atual e aplica as migrations.
  static Future<AppDatabase> open() async {
    Database? rawDatabase;
    try {
      rawDatabase = await openAppDatabase();
      final appDatabase = AppDatabase(rawDatabase);
      await appDatabase.initialize();
      return appDatabase;
    } catch (error) {
      if (rawDatabase != null) {
        await rawDatabase.close();
      }
      throw DatabaseOpenException(cause: error);
    }
  }

  /// Aplica as migrations de forma idempotente.
  Future<void> initialize() {
    return applyMigrations(database);
  }

  /// Fecha o banco. Chamadas repetidas são seguras.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await database.close();
  }
}
