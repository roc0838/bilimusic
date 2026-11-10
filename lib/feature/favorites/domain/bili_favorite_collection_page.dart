import 'package:bilimusic/feature/favorites/domain/favorite_collection.dart';
import 'package:bilimusic/feature/favorites/domain/favorite_entry.dart';

class BiliFavoriteCollectionPage {
  const BiliFavoriteCollectionPage({
    required this.collection,
    required this.items,
    required this.hasMore,
    required this.pageNumber,
  });

  final FavoriteCollection collection;
  final List<FavoriteEntry> items;
  final bool hasMore;
  final int pageNumber;
}
