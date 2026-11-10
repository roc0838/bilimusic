import 'package:bilimusic/common/domain/collection_kind.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';

/// 一条纯本地的收听记录。
///
/// 以 [stableId]（bvid + cid）为键，每个分 P 各自独立保存播放位置，
/// 不读取也不上报 B 站云端历史。
class ListeningHistoryEntry {
  const ListeningHistoryEntry({
    required this.stableId,
    required this.aid,
    required this.bvid,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAtMs,
    required this.completed,
    this.kindIndex = 0,
    this.collectionId,
    this.ownerMid,
    this.cid,
    this.page,
    this.pageTitle,
  });

  factory ListeningHistoryEntry.fromPlayableItem(
    PlayableItem item, {
    required Duration position,
    required Duration? duration,
    required bool completed,
    required int updatedAtMs,
  }) {
    return ListeningHistoryEntry(
      stableId: item.stableId,
      aid: item.aid,
      bvid: item.bvid,
      title: item.title,
      author: item.author,
      coverUrl: item.coverUrl,
      kindIndex: item.kind.index,
      collectionId: item.collectionId,
      ownerMid: item.ownerMid,
      cid: item.cid,
      page: item.page,
      pageTitle: item.pageTitle,
      positionMs: position < Duration.zero ? 0 : position.inMilliseconds,
      durationMs: duration == null || duration < Duration.zero
          ? 0
          : duration.inMilliseconds,
      updatedAtMs: updatedAtMs,
      completed: completed,
    );
  }

  factory ListeningHistoryEntry.fromJson(Map<String, dynamic> json) {
    int readInt(String key) {
      final Object? value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    int? readNullableInt(String key) {
      final Object? value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    String readString(String key) {
      final Object? value = json[key];
      return value is String ? value : '';
    }

    String? readNullableString(String key) {
      final Object? value = json[key];
      return value is String ? value : null;
    }

    final int rawKindIndex = readInt('kindIndex');
    final int kindIndex =
        rawKindIndex >= 0 && rawKindIndex < CollectionKind.values.length
        ? rawKindIndex
        : 0;

    return ListeningHistoryEntry(
      stableId: readString('stableId'),
      aid: readInt('aid'),
      bvid: readString('bvid'),
      title: readString('title'),
      author: readString('author'),
      coverUrl: readString('coverUrl'),
      kindIndex: kindIndex,
      collectionId: readNullableString('collectionId'),
      ownerMid: readNullableInt('ownerMid'),
      cid: readNullableInt('cid'),
      page: readNullableInt('page'),
      pageTitle: readNullableString('pageTitle'),
      positionMs: readInt('positionMs'),
      durationMs: readInt('durationMs'),
      updatedAtMs: readInt('updatedAtMs'),
      completed: json['completed'] == true,
    );
  }

  final String stableId;
  final int aid;
  final String bvid;
  final String title;
  final String author;
  final String coverUrl;
  final int kindIndex;
  final String? collectionId;
  final int? ownerMid;
  final int? cid;
  final int? page;
  final String? pageTitle;
  final int positionMs;
  final int durationMs;
  final int updatedAtMs;
  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'stableId': stableId,
    'aid': aid,
    'bvid': bvid,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'kindIndex': kindIndex,
    'collectionId': collectionId,
    'ownerMid': ownerMid,
    'cid': cid,
    'page': page,
    'pageTitle': pageTitle,
    'positionMs': positionMs,
    'durationMs': durationMs,
    'updatedAtMs': updatedAtMs,
    'completed': completed,
  };

  bool get isValid => stableId.isNotEmpty && title.isNotEmpty;

  Duration get position => Duration(milliseconds: positionMs < 0 ? 0 : positionMs);

  Duration get duration => Duration(milliseconds: durationMs < 0 ? 0 : durationMs);

  bool get isNearEnd => durationMs > 0 && positionMs >= durationMs * 0.95;

  /// 播完（或听到 95% 以上）后再次点开，从头开始。
  Duration get resumePosition {
    if (completed || isNearEnd || positionMs < 1000) {
      return Duration.zero;
    }
    return position;
  }

  double get progress => durationMs <= 0
      ? 0.0
      : (positionMs / durationMs).clamp(0.0, 1.0).toDouble();

  /// 同一个多 P 资源在列表里只展示最近收听的那一集。
  String get groupKey {
    final String? id = collectionId;
    if (id != null && id.isNotEmpty) {
      return 'collection:$id';
    }
    return 'video:${bvid.isNotEmpty ? bvid : 'aid:$aid'}';
  }

  String get partLabel {
    final int? value = page;
    if (value != null && value > 0) {
      return 'P$value';
    }
    return '';
  }

  CollectionKind get kind => CollectionKind.values[kindIndex];

  PlayableItem toPlayableItem() => PlayableItem(
    aid: aid,
    bvid: bvid,
    title: title,
    author: author,
    coverUrl: coverUrl,
    kind: kind,
    collectionId: collectionId,
    ownerMid: ownerMid,
    cid: cid,
    page: page,
    pageTitle: pageTitle,
  );
}
