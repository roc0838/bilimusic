import 'dart:async';

import 'package:bilimusic/feature/listening_history/data/listening_history_local_repository.dart';
import 'package:bilimusic/feature/listening_history/domain/listening_history_entry.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';

/// 播放器侧的轻量记录器：按音频文件（分 P）保存位置，并给出续播位置。
///
/// 只写本地 Hive，不访问 B 站历史接口，也不触发任何冲突提示。
class ListeningHistoryTracker {
  ListeningHistoryTracker({ListeningHistoryLocalRepository? repository})
    : _repository = repository ?? const ListeningHistoryLocalRepository();

  static const Duration _saveInterval = Duration(seconds: 10);

  final ListeningHistoryLocalRepository _repository;

  PlayableItem? _item;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _completed = false;
  bool _hasPlayed = false;
  DateTime? _lastSavedAt;
  Future<void> _writes = Future<void>.value();

  /// 每次开始加载一首新曲目时调用，重置上下文。
  void begin(PlayableItem item, Duration position, Duration? duration) {
    _item = item.hasIdentity ? item : null;
    _position = position < Duration.zero ? Duration.zero : position;
    _duration = duration;
    _completed = false;
    _hasPlayed = false;
    _lastSavedAt = null;
  }

  /// 播放中的位置回调，内部按 10 秒节流写盘。
  void onPosition(PlayableItem? item, Duration position, Duration? duration) {
    if (item == null || !item.hasIdentity) return;
    if (_item == null || _item!.stableId != item.stableId) {
      begin(item, position, duration);
    }
    _position = position < Duration.zero ? Duration.zero : position;
    if (duration != null && duration > Duration.zero) {
      _duration = duration;
    }
    if (_position <= Duration.zero) return;
    _hasPlayed = true;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastSavedAt;
    if (last != null && now.difference(last) < _saveInterval) return;
    _lastSavedAt = now;
    unawaited(flush());
  }

  void onSeek(Duration position) {
    _position = position < Duration.zero ? Duration.zero : position;
    _completed = false;
    if (_position > Duration.zero) _hasPlayed = true;
    unawaited(flush());
  }

  /// 播完：位置归零并标记，下次点开从头播放。
  void onCompleted() {
    _completed = true;
    _position = Duration.zero;
    _hasPlayed = true;
    unawaited(flush());
  }

  /// 切歌 / 暂停 / 退出时立即落盘。
  Future<void> flush() {
    final PlayableItem? item = _item;
    if (item == null || !_hasPlayed) return _writes;
    final ListeningHistoryEntry entry =
        ListeningHistoryEntry.fromPlayableItem(
          item,
          position: _completed ? Duration.zero : _position,
          duration: _duration,
          completed: _completed,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
    _lastSavedAt = DateTime.now();
    _writes = _writes
        .then<void>((_) => _repository.save(entry))
        .catchError((Object error, StackTrace stack) {});
    return _writes;
  }

  /// 返回 null 表示没有本地记录；返回 Duration.zero 表示有记录但应从头播。
  Duration? resumePositionFor(String stableId) {
    final ListeningHistoryEntry? entry = _repository.read(stableId);
    if (entry == null) return null;
    return entry.resumePosition;
  }
}
