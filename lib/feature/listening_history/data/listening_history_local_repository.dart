import 'dart:convert';

import 'package:bilimusic/feature/listening_history/domain/listening_history_entry.dart';
import 'package:hive_ce/hive.dart';

const String listeningHistoryBoxName = 'listening_history';

/// 独立的本地 Hive 盒子，和 B 站历史 / 收听进度同步逻辑完全隔离。
class ListeningHistoryLocalRepository {
  const ListeningHistoryLocalRepository();

  static const int maxEntries = 500;

  Box<String> get _box => Hive.box<String>(listeningHistoryBoxName);

  List<ListeningHistoryEntry> load() {
    final List<ListeningHistoryEntry> entries = <ListeningHistoryEntry>[];
    for (final String raw in _box.values) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final ListeningHistoryEntry entry = ListeningHistoryEntry.fromJson(
          decoded,
        );
        if (entry.isValid) entries.add(entry);
      } on Object {
        continue;
      }
    }
    entries.sort(
      (ListeningHistoryEntry a, ListeningHistoryEntry b) =>
          b.updatedAtMs.compareTo(a.updatedAtMs),
    );
    return entries;
  }

  ListeningHistoryEntry? read(String stableId) {
    if (stableId.isEmpty) return null;
    for (final ListeningHistoryEntry entry in load()) {
      if (entry.stableId == stableId) return entry;
    }
    return null;
  }

  Future<void> save(ListeningHistoryEntry entry) async {
    if (!entry.isValid) return;
    await _box.put(entry.stableId, jsonEncode(entry.toJson()));
    final List<ListeningHistoryEntry> all = load();
    if (all.length <= maxEntries) return;
    final List<dynamic> stale = <dynamic>[
      for (final ListeningHistoryEntry old in all.skip(maxEntries))
        old.stableId,
    ];
    await _box.deleteAll(stale);
  }

  Future<void> remove(String stableId) => _box.delete(stableId);

  Future<void> clear() => _box.clear();
}
