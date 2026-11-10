import 'package:bilimusic/feature/player/domain/playable_item.dart';

class FavoritesImportCandidate {
  const FavoritesImportCandidate({
    required this.aid,
    required this.bvid,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.durationText,
    required this.durationMs,
    required this.score,
  });

  final int aid;
  final String bvid;
  final String title;
  final String author;
  final String coverUrl;
  final String durationText;
  final int durationMs;
  final int score;

  PlayableItem toPlayableItem() {
    return PlayableItem(
      aid: aid,
      bvid: bvid,
      title: title,
      author: author,
      coverUrl: coverUrl,
      page: 1,
      durationText: durationText,
    );
  }
}
