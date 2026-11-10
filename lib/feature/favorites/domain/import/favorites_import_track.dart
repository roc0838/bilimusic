class FavoritesImportTrack {
  const FavoritesImportTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.durationMs,
  });

  final String id;
  final String title;
  final String author;
  final int durationMs;

  String get searchKeyword {
    final String cleanTitle = title.trim();
    final String cleanAuthor = author.trim();
    if (cleanTitle.isEmpty && cleanAuthor.isEmpty) {
      return '';
    }
    if (cleanAuthor.isEmpty) {
      return cleanTitle;
    }
    if (cleanTitle.isEmpty) {
      return cleanAuthor;
    }
    return '[$cleanTitle-$cleanAuthor]';
  }
}
