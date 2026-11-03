import 'package:sembast/sembast.dart';

import 'stores.dart';

export 'stores.dart' show metaStore;

/// Versão atual do formato de dados.
///
/// Histórico:
/// - 1: store `meta` (schemaVersion e createdAt).
/// - 2: stores `people`, `events`, `participants` e `groups`.
/// - 3: stores `draws`, `assignments` e `deliveries`.
const int currentSchemaVersion = 3;

/// Prepara o banco e registra a versão do schema de forma idempotente.
Future<void> applyMigrations(Database db) async {
  await db.transaction((txn) async {
    final versionRecord = await metaStore.record('schemaVersion').get(txn);
    final storedVersion = (versionRecord?['value'] as num?)?.toInt() ?? 0;

    if (storedVersion > currentSchemaVersion) {
      throw StateError('Versão de dados não suportada por este aplicativo.');
    }

    if (storedVersion < 1) {
      await metaStore.record('schemaVersion').put(txn, {'value': 1});
    }

    // A versão 2 apenas adiciona stores de documentos. Não há dados antigos
    // para transformar, então a migração é apenas o registro da versão.
    if (storedVersion < 2) {
      await metaStore.record('schemaVersion').put(txn, {'value': 2});
    }

    if (storedVersion < 3) {
      await metaStore.record('schemaVersion').put(txn, {'value': 3});
    }

    final createdAt = await metaStore.record('createdAt').get(txn);
    if (createdAt == null) {
      await metaStore.record('createdAt').put(txn, {
        'value': DateTime.now().toUtc().toIso8601String(),
      });
    }
  });
}
