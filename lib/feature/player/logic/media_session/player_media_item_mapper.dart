import 'package:audio_service/audio_service.dart';
import 'package:bilimusic/feature/player/domain/audio_stream_info.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';
import 'package:bilimusic/feature/player/domain/player_display_info.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_metadata.dart';

MediaItem buildPlayerMediaItem(
  PlayableItem item, {
  required AudioStreamInfo audioStream,
  required String? queueSourceLabel,
  Duration? duration,
  PlayerDisplayInfo? display,
  String? lockScreenLyricLine,
}) {
  final String pageTitle = audioStream.pageTitle?.trim() ?? '';
  final String qualityLabel = audioStream.qualityLabel?.trim() ?? '';
  final List<String> descriptionParts = <String>[
    if (pageTitle.isNotEmpty) pageTitle,
    if (qualityLabel.isNotEmpty) qualityLabel,
  ];

  return buildPlayerQueueMediaItem(
    item,
    queueSourceLabel: queueSourceLabel,
    duration: duration ?? audioStream.duration,
    display: display,
    lockScreenLyricLine: lockScreenLyricLine,
  ).copyWith(displayDescription: descriptionParts.join(' · '));
}

MediaItem buildPlayerQueueMediaItem(
  PlayableItem item, {
  required String? queueSourceLabel,
  Duration? duration,
  PlayerDisplayInfo? display,
  String? lockScreenLyricLine,
}) {
  final PlayerDisplayInfo info =
      !item.isSpoken && display?.stableId == item.stableId
      ? display!
      : resolvePlayerDisplayInfo(
          item: item,
          metadata: null,
          source: PlayerDisplaySource.bilibili,
        );
  final String album = queueSourceLabel?.trim() ?? '';
  // iOS 锁屏 / 控制中心没有歌词字段，只能借用 Now Playing 的副标题行。
  // 只有真正解析到当前歌词行时才替换，其余情况与原来的歌手信息完全一致。
  final String lyricLine = lockScreenLyricLine?.trim() ?? '';

  return MediaItem(
    id: item.stableId,
    album: album.isEmpty ? 'Bilibili' : album,
    title: info.title ?? item.title,
    artist: info.artist ?? item.author,
    artUri: info.coverUrl == null ? null : Uri.tryParse(info.coverUrl!),
    duration: duration,
    displayTitle: info.title ?? item.title,
    displaySubtitle: lyricLine.isEmpty
        ? (info.artist ?? item.author)
        : lyricLine,
    displayDescription: item.pageTitle?.trim() ?? '',
    // 供锁屏 / 车机的媒体会话识别分P与来源，不影响现有 UI。
    extras: <String, dynamic>{
      'stableId': item.stableId,
      'bvid': item.bvid,
      'aid': item.aid,
      'cid': item.cid,
      'page': item.page,
      'pageTitle': item.pageTitle,
    },
  );
}
