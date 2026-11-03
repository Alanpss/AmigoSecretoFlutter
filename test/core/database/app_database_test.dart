import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/database/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database rawDatabase;
  late AppDatabase appDatabase;

  setUp(() async {
    rawDatabase = await databaseFactoryMemory.openDatabase(
      'app_database_test.db',
    );
    appDatabase = AppDatabase(rawDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('inicializa a versão e os metadados uma única vez', () async {
    await appDatabase.initialize();

    final version = await metaStore.record('schemaVersion').get(rawDatabase);
    final createdAt = await metaStore.record('createdAt').get(rawDatabase);

    expect(version?['value'], currentSchemaVersion);
    expect(createdAt?['value'], isA<String>());

    final recordCount = await metaStore.count(rawDatabase);
    await appDatabase.initialize();

    expect(await metaStore.count(rawDatabase), recordCount);
  });

  test('transação com erro não grava nada', () async {
    final events = stringMapStoreFactory.store('events');

    await expectLater(
      rawDatabase.transaction((transaction) async {
        await events.record('event-1').put(transaction, {'name': 'Teste'});
        throw StateError('falha simulada');
      }),
      throwsA(isA<StateError>()),
    );

    expect(await events.record('event-1').get(rawDatabase), isNull);
  });

  test('migra schema 1 para 3 e preserva os metadados existentes', () async {
    const createdAt = '2026-01-01T12:00:00.000Z';
    await metaStore.record('schemaVersion').put(rawDatabase, {'value': 1});
    await metaStore.record('createdAt').put(rawDatabase, {'value': createdAt});

    await appDatabase.initialize();

    expect(
      (await metaStore.record('schemaVersion').get(rawDatabase))?['value'],
      currentSchemaVersion,
    );
    expect(
      (await metaStore.record('createdAt').get(rawDatabase))?['value'],
      createdAt,
    );
  });

  test('migra schema 2 para 3', () async {
    await metaStore.record('schemaVersion').put(rawDatabase, {'value': 2});
    await appDatabase.initialize();
    expect(
      (await metaStore.record('schemaVersion').get(rawDatabase))?['value'],
      3,
    );
  });
}
