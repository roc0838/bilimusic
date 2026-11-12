import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bilimusic/feature/metadata/domain/metadata_state.dart';
import 'package:bilimusic/feature/metadata/logic/metadata_controller.dart';
import 'package:bilimusic/feature/player/domain/player_display_info.dart';
import 'package:bilimusic/feature/player/domain/player_state.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_metadata.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_provider.dart';
import 'package:bilimusic/feature/player/logic/lyrics/desktop_lyrics_controller.dart';
import 'package:bilimusic/feature/player/logic/media_session/app_audio_handler.dart';
import 'package:bilimusic/feature/player/logic/media_session/player_media_item_mapper.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_media_session_sync.g.dart';

@riverpod
void playerMediaSessionSync(Ref ref) {
  final AppAudioHandler handler = ref.watch(appAudioHandlerProvider);

  void publish() {
    final PlayerState state = ref.read(playerControllerProvider);
    final PlayerDisplayInfo display = ref.read(playerDisplayProvider);
    final String? lyricLine = resolveLockScreenLyricLine(
      state: state,
      metadata: ref.read(metadataControllerProvider),
    );
    final List<MediaItem> queue = state.queue
        .map(
          (item) => buildPlayerQueueMediaItem(
            item,
            queueSourceLabel: state.queueSourceLabel,
            duration: item.stableId == state.currentItem?.stableId
                ? state.duration ?? state.audioStream?.duration
                : null,
            display: display,
          ),
        )
        .toList(growable: false);
    final item = state.currentItem;
    final stream = state.audioStream;
    // 歌词只作用于「当前曲目」的 Now Playing 副标题，队列里的其他分 P
    // 仍显示歌手信息，避免锁屏选曲列表被歌词刷屏。
    final MediaItem? current = item == null
        ? null
        : stream == null
        ? buildPlayerQueueMediaItem(
            item,
            queueSourceLabel: state.queueSourceLabel,
            duration: state.duration,
            display: display,
            lockScreenLyricLine: lyricLine,
          )
        : buildPlayerMediaItem(
            item,
            audioStream: stream,
            queueSourceLabel: state.queueSourceLabel,
            duration: state.duration,
            display: display,
            lockScreenLyricLine: lyricLine,
          );
    if (!listEquals(
      handler.queue.value.map(_mediaContent).toList(growable: false),
      queue.map(_mediaContent).toList(growable: false),
    )) {
      unawaited(handler.updateQueue(queue));
    }
    if (_mediaContent(handler.mediaItem.value) != _mediaContent(current)) {
      handler.updateCurrentMediaItem(current);
    }
  }

  ref.listen(
    playerControllerProvider.select(
      (state) => (
        state.queue,
        state.currentItem,
        state.queueSourceLabel,
        state.duration,
        state.audioStream,
        // 只有 iOS 且当前曲目确实带歌词时，才让播放进度驱动锁屏刷新。
        // 其他情况恒为 0，保持原来「进度变化不重发媒体信息」的行为。
        _lockScreenLyricTick(ref, state),
      ),
    ),
    (_, _) => publish(),
  );
  ref.listen(
    metadataControllerProvider.select(
      (metadata) => (
        metadata.stableId,
        metadata.metadata?.stableId,
        metadata.metadata?.lyrics,
        metadata.metadata?.metaLyrics,
        metadata.metadata?.lyricOffsetMs,
        metadata.metadata?.lyricBaseOffsetMs,
      ),
    ),
    (_, _) => publish(),
  );
  ref.listen(
    playerDisplayProvider.select(
      (display) =>
          (display.stableId, display.title, display.artist, display.coverUrl),
    ),
    (_, _) => publish(),
    fireImmediately: true,
  );
}

/// iOS 的 MPNowPlayingInfoCenter 没有「歌词」字段，锁屏 / 控制中心
/// 只暴露标题、副标题、专辑、封面。这里把当前时间轴对应的那句歌词
/// 放进副标题行（逐句更新，不是逐字滚动），未匹配到歌词时返回 null，
/// 锁屏显示的仍是原来的歌手信息。
String? resolveLockScreenLyricLine({
  required PlayerState state,
  required MetadataState metadata,
}) {
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    return null;
  }
  final item = state.currentItem;
  if (item == null || item.isSpoken || metadata.stableId != item.stableId) {
    return null;
  }
  final String? rawLyrics = resolveDisplayLyrics(metadata.metadata);
  if (rawLyrics == null) {
    return null;
  }
  final DesktopLyricFrame? frame = resolveDesktopLyricFrame(
    rawLyrics,
    position: state.position,
    offsetMs: resolveDisplayLyricOffsetMs(metadata.metadata),
  );
  final String line = frame?.line.trim() ?? '';
  if (line.isEmpty) {
    return null;
  }
  // 锁屏副标题只有一行，超长歌词提前截断，避免系统省略号把整句吃掉。
  return line.length > 72 ? '${line.substring(0, 72)}…' : line;
}

int _lockScreenLyricTick(Ref ref, PlayerState state) {
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    return 0;
  }
  final MetadataState metadata = ref.read(metadataControllerProvider);
  final item = state.currentItem;
  if (item == null ||
      item.isSpoken ||
      metadata.stableId != item.stableId ||
      resolveDisplayLyrics(metadata.metadata) == null) {
    return 0;
  }
  return state.position.inMilliseconds ~/ 1500;
}

Record? _mediaContent(MediaItem? item) => item == null
    ? null
    : (
        item.id,
        item.album,
        item.title,
        item.artist,
        item.artUri,
        item.duration,
        item.displayTitle,
        item.displaySubtitle,
        item.displayDescription,
      );
