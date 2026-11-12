import 'package:sembast/sembast.dart';

import '../../../core/database/stores.dart';

/// Local browser/device draft for the organizer form. It is intentionally not
/// registered in BackupService: online links are bearer credentials.
class OnlineDrawDraftRepository {
  OnlineDrawDraftRepository(this._database);

  static const _recordKey = 'current';
  final Database _database;

  Future<Map<String, Object?>?> load() async {
    final value = await onlineDraftsStore.record(_recordKey).get(_database);
    return value == null ? null : Map<String, Object?>.from(value);
  }

  Future<void> save(Map<String, Object?> draft) async {
    await onlineDraftsStore.record(_recordKey).put(_database, draft);
  }

  Future<void> clear() async {
    await onlineDraftsStore.record(_recordKey).delete(_database);
  }
}
