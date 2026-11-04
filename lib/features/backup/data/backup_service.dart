import 'dart:async';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';

import '../../../core/database/stores.dart';
import '../domain/backup_document.dart';

typedef BackupStoreWriteHook = FutureOr<void> Function(String storeName);

/// Serializa e restaura todos os stores em uma única transação.
class BackupService {
  BackupService(
    this._database, {
    DateTime Function()? now,
    this._beforeStoreWrite,
  }) : _now = now ?? _systemNow;

  final Database _database;
  final DateTime Function() _now;
  final BackupStoreWriteHook? _beforeStoreWrite;

  static final Map<String, StoreRef<String, Map<String, Object?>>> _stores = {
    'meta': metaStore,
    'people': peopleStore,
    'events': eventsStore,
    'participants': participantsStore,
    'groups': groupsStore,
    'draws': drawsStore,
    'assignments': assignmentsStore,
    'deliveries': deliveriesStore,
    'settings': settingsStore,
  };

  Future<Uint8List> exportBytes() async {
    final data = <String, List<BackupEntry>>{};
    for (final name in backupStoreNames) {
      final records = await _stores[name]!.find(_database);
      records.sort((a, b) => a.key.compareTo(b.key));
      data[name] = records
          .map((record) => BackupEntry(key: record.key, value: record.value))
          .toList(growable: false);
    }

    final document = BackupDocument(exportedAt: _now().toUtc(), stores: data);
    final bytes = document.toBytes();
    BackupDocument.decode(bytes);
    return bytes;
  }

  BackupDocument parse(Uint8List bytes) => BackupDocument.decode(bytes);

  Future<BackupPreview> importBytes(Uint8List bytes) async {
    final document = BackupDocument.decode(bytes);
    await importDocument(document);
    return document.preview;
  }

  Future<void> importDocument(BackupDocument document) async {
    // Revalidate even when the document was constructed by another caller.
    final validated = BackupDocument.decode(document.toBytes());
    await _database.transaction((transaction) async {
      for (final name in backupStoreNames) {
        await _beforeStoreWrite?.call(name);
        await _stores[name]!.delete(transaction);
        for (final entry in validated.stores[name]!) {
          await _stores[name]!.record(entry.key).put(transaction, entry.value);
        }
      }
    });
  }

  static String fileName(DateTime date) {
    final day = date.toUtc().toIso8601String().substring(0, 10);
    return 'amigo-secreto-backup-$day.json';
  }
}

DateTime _systemNow() => DateTime.now().toUtc();

/// Borda de arquivo para exportar e selecionar backups.
abstract interface class BackupFileService {
  Future<BackupSaveResult> save({
    required String fileName,
    required Uint8List bytes,
  });

  Future<Uint8List?> pick({required int maxBytes});
}

enum BackupSaveResult { cancelled, saved, downloadStarted }
