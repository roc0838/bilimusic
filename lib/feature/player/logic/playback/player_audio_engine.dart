import 'dart:async';

import 'package:media_kit/media_kit.dart' as media_kit;

class PlayerAudioEngine {
  PlayerAudioEngine() : _player = media_kit.Player() {
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _player.stream.playing.listen((_) => _emitPlayerState()),
      _player.stream.buffering.listen((_) => _emitPlayerState()),
      _player.stream.completed.listen((dynamic completed) {
        // mpv 的 EOF 标记是播放器级的，换源后旧值可能仍残留。这里只接受
        // 「当前源已就绪、且已经发起过播放」之后上报的完成事件，避免上一首
        // 的 completed 把下一首的状态污染成已完成（表现为切歌后不播放）。
        if (_hasSource && !_isOpening && !_awaitingFirstPlay) {
          _completedForCurrentSource = completed == true;
        }
        _emitPlayerState();
      }),
    ]);
  }

  final media_kit.Player _player;
  final StreamController<PlayerEngineState> _playerStateController =
      StreamController<PlayerEngineState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  bool _hasSource = false;
  bool _isOpening = false;
  bool _completedForCurrentSource = false;
  bool _awaitingFirstPlay = false;

  bool get playing => _player.state.playing;
  double get volume => _player.state.volume / 100.0;
  Duration get position => _player.state.position;
  PlayerEngineProcessingState get processingState => _processingState;

  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get bufferedPositionStream => _player.stream.buffer;
  Stream<Duration?> get durationStream => _player.stream.duration.map(
    (Duration duration) => duration == Duration.zero ? null : duration,
  );
  Stream<PlayerEngineException> get errorStream =>
      _player.stream.error.map(PlayerEngineException.new);
  Stream<double> get volumeStream => _player.stream.volume.map(
    (double volume) => (volume / 100.0).clamp(0.0, 1.0).toDouble(),
  );
  Stream<PlayerEngineState> get playerStateStream =>
      _playerStateController.stream;

  Future<Duration?> setRemoteSource({
    required Uri uri,
    Map<String, String>? headers,
    Duration? initialPosition,
  }) async {
    await _openMedia(
      media_kit.Media(uri.toString(), httpHeaders: headers),
      initialPosition: initialPosition,
    );
    return _durationOrNull;
  }

  Future<Duration?> setFileSource({
    required String filePath,
    Duration? initialPosition,
  }) async {
    await _openMedia(
      media_kit.Media(Uri.file(filePath).toString()),
      initialPosition: initialPosition,
    );
    return _durationOrNull;
  }

  Future<void> play() async {
    // 首次开播即解除「换源保护」；此后收到的才是当前这首真正的 EOF。
    _awaitingFirstPlay = false;
    final bool currentSourceFinished = _completedForCurrentSource;
    _completedForCurrentSource = false;
    if (_player.state.completed) {
      // mpv 停留在 EOF 时不会响应 play()。换源后的残留 EOF 要保持当前
      // 位置（可能是续播点）；同一首真正播完后再点播放则从头开始。
      await _player.seek(
        currentSourceFinished ? Duration.zero : _player.state.position,
      );
    }
    await _player.play();
    _emitPlayerState();
  }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _hasSource = false;
    _isOpening = false;
    _completedForCurrentSource = false;
    _awaitingFirstPlay = false;
    _emitPlayerState();
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0.0, 1.0) * 100.0);
  }

  // 依赖 mpv 的 speed 是 player 级属性（换源不重置），故 open 后不重放速率。
  // ponytail: 若某平台实测换源后回到 1.0x，在 _openMedia 里补一次 setRate。
  Future<void> setRate(double rate) {
    return _player.setRate(rate);
  }

  Future<void> dispose() async {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _playerStateController.close();
    await _player.dispose();
  }

  Future<void> _openMedia(
    media_kit.Media media, {
    Duration? initialPosition,
  }) async {
    _hasSource = false;
    _isOpening = true;
    _completedForCurrentSource = false;
    _awaitingFirstPlay = true;
    _emitPlayerState();
    try {
      await _player.open(media, play: false);
      _completedForCurrentSource = false;
      _hasSource = true;
      final Duration? position = initialPosition;
      if (position != null && position > Duration.zero) {
        // 等待音频就绪
        if (_player.state.duration <= Duration.zero) {
          await _player.stream.duration
              .firstWhere((Duration value) => value > Duration.zero)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => Duration.zero,
              );
        }
        await _player.seek(position);
      }
    } finally {
      _isOpening = false;
      _emitPlayerState();
    }
  }

  Duration? get _durationOrNull {
    final Duration duration = _player.state.duration;
    return duration == Duration.zero ? null : duration;
  }

  PlayerEngineProcessingState get _processingState {
    final media_kit.PlayerState state = _player.state;
    if (_isOpening) {
      return PlayerEngineProcessingState.loading;
    }
    if (!_hasSource) {
      return PlayerEngineProcessingState.idle;
    }
    if (_completedForCurrentSource) {
      return PlayerEngineProcessingState.completed;
    }
    if (state.buffering) {
      return PlayerEngineProcessingState.buffering;
    }
    return PlayerEngineProcessingState.ready;
  }

  void _emitPlayerState() {
    if (_playerStateController.isClosed) {
      return;
    }
    _playerStateController.add(
      PlayerEngineState(
        playing: _player.state.playing,
        processingState: _processingState,
      ),
    );
  }
}

class PlayerEngineState {
  const PlayerEngineState({
    required this.playing,
    required this.processingState,
  });

  final bool playing;
  final PlayerEngineProcessingState processingState;
}

class PlayerEngineException implements Exception {
  const PlayerEngineException(this.message, {this.code});

  final String message;
  final Object? code;

  @override
  String toString() {
    if (code == null) {
      return message;
    }
    return '$message (code: $code)';
  }
}

enum PlayerEngineProcessingState { idle, loading, buffering, ready, completed }

extension PlayerEngineProcessingStateX on PlayerEngineProcessingState {
  bool get isBuffering {
    return this == PlayerEngineProcessingState.loading ||
        this == PlayerEngineProcessingState.buffering;
  }

  bool get isReady {
    return this != PlayerEngineProcessingState.idle &&
        this != PlayerEngineProcessingState.loading;
  }
}
