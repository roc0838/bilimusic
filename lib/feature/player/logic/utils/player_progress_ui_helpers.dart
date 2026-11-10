import 'package:bilimusic/feature/player/domain/player_state.dart';
import 'package:bilimusic/feature/player/logic/player_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

PlayerProgressSnapshot resolvePlayerProgressSnapshot(
  AsyncValue<PlayerProgressSnapshot> progressAsync,
  PlayerState fallbackState,
) {
  return switch (progressAsync) {
    AsyncData<PlayerProgressSnapshot>(:final value) => value,
    _ => (
      position: fallbackState.position,
      duration: fallbackState.duration,
      isReady: fallbackState.isReady,
    ),
  };
}
