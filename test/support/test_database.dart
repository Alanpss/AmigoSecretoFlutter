import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:sembast/sembast_memory.dart';

int _databaseCounter = 0;

/// Abre um banco em memória já migrado para os testes.
Future<AppDatabase> createTestDatabase() async {
  final rawDatabase = await databaseFactoryMemory.openDatabase(
    'amigo_secreto_test_${_databaseCounter++}.db',
  );
  final database = AppDatabase(rawDatabase);
  await database.initialize();
  return database;
}
