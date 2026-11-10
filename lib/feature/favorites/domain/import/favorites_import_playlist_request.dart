import 'package:bilimusic/feature/favorites/domain/import/favorites_import_platform.dart';

class FavoritesImportPlaylistRequest {
  const FavoritesImportPlaylistRequest({
    required this.playlistId,
    required this.platform,
  });

  final String playlistId;
  final FavoritesImportPlatform platform;

  bool get isValid => playlistId.trim().isNotEmpty;

  FavoritesImportPlaylistRequest copyWith({
    String? playlistId,
    FavoritesImportPlatform? platform,
  }) {
    return FavoritesImportPlaylistRequest(
      playlistId: playlistId ?? this.playlistId,
      platform: platform ?? this.platform,
    );
  }
}
