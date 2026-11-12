import 'package:sembast/sembast.dart';

import '../../../core/database/stores.dart';

/// Local browser/device draft for the organizer form. It is intentionally not
/// registered in BackupService: online links are bearer credentials.
class OnlineDrawDraftRepository {
  OnlineDrawDraftRepository(this._database);

  static const _legacyRecordKey = 'current';
  final Database _database;

  /// Loads one draft by its stable online event ID. With no ID, returns the
  /// most recently saved draft for backwards compatibility with old callers.
  Future<Map<String, Object?>?> load({String? eventId}) async {
    final drafts = await list();
    if (eventId != null) {
      for (final draft in drafts) {
        if (draft['eventId'] == eventId) return draft;
      }
      return null;
    }
    return drafts.isEmpty ? null : drafts.first;
  }

  /// Returns all locally managed online drafts, migrating the former single
  /// `current` record to its event ID the first time it is read.
  Future<List<Map<String, Object?>>> list() async {
    final records = await onlineDraftsStore.find(_database);
    final drafts = <Map<String, Object?>>[];
    final seenEventIds = <String>{};
    for (final record in records) {
      var draft = Map<String, Object?>.from(record.value);
      final eventId = draft['eventId'];
      if (eventId is! String || eventId.isEmpty) continue;
      if (record.key == _legacyRecordKey) {
        await _database.transaction((txn) async {
          final existing = await onlineDraftsStore.record(eventId).get(txn);
          if (existing == null) {
            await onlineDraftsStore.record(eventId).put(txn, draft);
          } else {
            draft = Map<String, Object?>.from(existing);
          }
          await onlineDraftsStore.record(_legacyRecordKey).delete(txn);
        });
      }
      if (!seenEventIds.add(eventId)) continue;
      drafts.add(draft);
    }
    drafts.sort((a, b) {
      final aUpdated = a['updatedAt'] as String? ?? '';
      final bUpdated = b['updatedAt'] as String? ?? '';
      final byUpdated = bUpdated.compareTo(aUpdated);
      return byUpdated != 0
          ? byUpdated
          : (a['eventName'] as String? ?? '').compareTo(
              b['eventName'] as String? ?? '',
            );
    });
    return drafts;
  }

  Future<void> save(Map<String, Object?> draft) async {
    final eventId = draft['eventId'];
    if (eventId is! String || eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'draft.eventId', 'Required');
    }
    final value = Map<String, Object?>.from(draft)
      ..['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    await onlineDraftsStore.record(eventId).put(_database, value);
  }

  Future<void> clear({required String eventId}) async {
    await onlineDraftsStore.record(eventId).delete(_database);
  }
}
