import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AppAudioHandler> appAudioHandlerProvider =
    Provider<AppAudioHandler>((Ref ref) {
      return PlayerAudioService.handler;
    });

abstract interface class PlayerCommandTarget {
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToQueueItem(int index);
}

class PlayerAudioService {
  PlayerAudioService._();

  static AppAudioHandler? _handler;

  static AppAudioHandler get handler {
    final AppAudioHandler? handler = _handler;
    if (handler == null) {
      throw StateError('PlayerAudioService has not been initialized.');
    }
    return handler;
  }

  static Future<void> initialize() async {
    if (_handler != null) {
      return;
    }

    final AudioHandler audioHandler = await AudioService.init(
      builder: AppAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.bilimusic.channel.audio',
        androidNotificationChannelName: 'Bilimusic Playback',
        androidNotificationOngoing: true,
      ),
    );

    _handler = audioHandler as AppAudioHandler;
  }
}

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  PlayerCommandTarget? _target;

  void attachTarget(PlayerCommandTarget target) {
    _target = target;
  }

  void detachTarget(PlayerCommandTarget target) {
    if (identical(_target, target)) {
      _target = null;
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(List<MediaItem>.unmodifiable(queue));
  }

  void updateCurrentMediaItem(MediaItem? item) {
    mediaItem.add(item);
  }

  void updatePlaybackSnapshot({
    required bool isPlaying,
    required bool isBuffering,
    required bool hasPrevious,
    required bool hasNext,
    required Duration position,
    required Duration bufferedPosition,
    required int? queueIndex,
    required double speed,
    required AudioProcessingState processingState,
  }) {
    final List<MediaControl> controls = <MediaControl>[
      MediaControl.rewind,
      if (hasPrevious) MediaControl.skipToPrevious,
      isPlaying ? MediaControl.pause : MediaControl.play,
      if (hasNext) MediaControl.skipToNext,
      MediaControl.fastForward,
      MediaControl.stop,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: _compactActionIndices(controls),
        processingState: processingState,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: speed,
        queueIndex: queueIndex,
      ),
    );
  }

  List<int> _compactActionIndices(List<MediaControl> controls) {
    final List<int> indices = <int>[];
    for (int index = 0; index < controls.length; index++) {
      final MediaAction action = controls[index].action;
      if (action == MediaAction.skipToPrevious ||
          action == MediaAction.play ||
          action == MediaAction.pause ||
          action == MediaAction.skipToNext) {
        indices.add(index);
      }
    }
    return indices.take(3).toList(growable: false);
  }

  @override
  Future<void> play() async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.play();
  }

  @override
  Future<void> pause() async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.pause();
  }

  @override
  Future<void> stop() async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.skipToPrevious();
  }

  /// 车机 / 锁屏从队列里直接选曲时走这里。
  @override
  Future<void> skipToQueueItem(int index) async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    await target.skipToQueueItem(index);
  }

  /// 方向盘 / 耳机上的快进快退（iOS remote command 的 skipForward /
  /// skipBackward 会落到这里），默认实现是空的，这里转成相对 seek。
  @override
  Future<void> fastForward() => _seekBy(const Duration(seconds: 15));

  @override
  Future<void> rewind() => _seekBy(const Duration(seconds: -15));

  Future<void> _seekBy(Duration offset) async {
    final PlayerCommandTarget? target = _target;
    if (target == null) {
      return;
    }
    final Duration current = playbackState.value.updatePosition;
    final Duration? duration = mediaItem.value?.duration;
    Duration next = current + offset;
    if (next < Duration.zero) {
      next = Duration.zero;
    }
    if (duration != null && duration > Duration.zero && next > duration) {
      next = duration;
    }
    await target.seek(next);
  }
}

AudioProcessingState mapAudioProcessingState(String processingStateName) {
  return switch (processingStateName) {
    'idle' => AudioProcessingState.idle,
    'loading' => AudioProcessingState.loading,
    'buffering' => AudioProcessingState.buffering,
    'ready' => AudioProcessingState.ready,
    'completed' => AudioProcessingState.completed,
    _ => AudioProcessingState.idle,
  };
}
