import 'package:bilimusic/feature/favorites/domain/import/favorites_import_candidate.dart';
import 'package:bilimusic/feature/favorites/domain/import/favorites_import_platform.dart';
import 'package:bilimusic/feature/favorites/domain/import/favorites_import_playlist_request.dart';
import 'package:bilimusic/feature/favorites/domain/import/favorites_import_result.dart';
import 'package:bilimusic/feature/favorites/domain/import/favorites_import_status.dart';
import 'package:bilimusic/feature/favorites/domain/import/favorites_import_track.dart';

class FavoritesImportState {
  const FavoritesImportState({
    required this.request,
    this.status = FavoritesImportStatus.idle,
    this.totalCount = 0,
    this.processedCount = 0,
    this.matchedCount = 0,
    this.failedCount = 0,
    this.currentTrack,
    this.currentCandidate,
    this.results = const <FavoritesImportResult>[],
    this.errorMessage,
    this.startedAt,
    this.finishedAt,
  });

  final FavoritesImportPlaylistRequest request;
  final FavoritesImportStatus status;
  final int totalCount;
  final int processedCount;
  final int matchedCount;
  final int failedCount;
  final FavoritesImportTrack? currentTrack;
  final FavoritesImportCandidate? currentCandidate;
  final List<FavoritesImportResult> results;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  bool get isRunning =>
      status == FavoritesImportStatus.loadingPlaylist ||
      status == FavoritesImportStatus.running ||
      status == FavoritesImportStatus.canceling;

  bool get canStart => !isRunning;

  FavoritesImportState copyWith({
    FavoritesImportPlaylistRequest? request,
    FavoritesImportStatus? status,
    int? totalCount,
    int? processedCount,
    int? matchedCount,
    int? failedCount,
    FavoritesImportTrack? currentTrack,
    FavoritesImportCandidate? currentCandidate,
    List<FavoritesImportResult>? results,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool clearCurrentTrack = false,
    bool clearCurrentCandidate = false,
    bool clearErrorMessage = false,
    bool clearStartedAt = false,
    bool clearFinishedAt = false,
  }) {
    return FavoritesImportState(
      request: request ?? this.request,
      status: status ?? this.status,
      totalCount: totalCount ?? this.totalCount,
      processedCount: processedCount ?? this.processedCount,
      matchedCount: matchedCount ?? this.matchedCount,
      failedCount: failedCount ?? this.failedCount,
      currentTrack: clearCurrentTrack ? null : currentTrack ?? this.currentTrack,
      currentCandidate: clearCurrentCandidate
          ? null
          : currentCandidate ?? this.currentCandidate,
      results: results ?? this.results,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      finishedAt: clearFinishedAt ? null : finishedAt ?? this.finishedAt,
    );
  }

  factory FavoritesImportState.initial() {
    return FavoritesImportState(
      request: FavoritesImportPlaylistRequest(
        playlistId: '',
        platform: FavoritesImportPlatform.netease,
      ),
    );
  }
}
