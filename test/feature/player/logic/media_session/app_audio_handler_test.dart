import 'package:audio_service/audio_service.dart';
import 'package:bilimusic/feature/player/logic/media_session/app_audio_handler.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTarget implements PlayerCommandTarget {
  final List<String> calls = <String>[];
  Duration? seekedTo;
  int? queueItemIndex;

  @override
  Future<void> play() async {
    calls.add('play');
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> seek(Duration position) async {
    seekedTo = position;
    calls.add('seek');
  }

  @override
  Future<void> skipToNext() async {
    calls.add('skipToNext');
  }

  @override
  Future<void> skipToPrevious() async {
    calls.add('skipToPrevious');
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    queueItemIndex = index;
    calls.add('skipToQueueItem');
  }
}

AppAudioHandler _buildHandler(_FakeTarget target) {
  final AppAudioHandler handler = AppAudioHandler();
  handler.attachTarget(target);
  handler.updatePlaybackSnapshot(
    isPlaying: true,
    isBuffering: false,
    hasPrevious: true,
    hasNext: true,
    position: const Duration(seconds: 10),
    bufferedPosition: const Duration(seconds: 30),
    queueIndex: 2,
    speed: 1,
    processingState: AudioProcessingState.ready,
  );
  return handler;
}

void main() {
  test('锁屏/车机选曲会转发到播放器队列', () async {
    final _FakeTarget target = _FakeTarget();
    final AppAudioHandler handler = _buildHandler(target);

    await handler.skipToQueueItem(5);

    expect(target.queueItemIndex, 5);
    expect(target.calls, <String>['skipToQueueItem']);
  });

  test('快进快退转成 ±15 秒的相对 seek', () async {
    final _FakeTarget target = _FakeTarget();
    final AppAudioHandler handler = _buildHandler(target);

    await handler.fastForward();
    expect(target.seekedTo, const Duration(seconds: 25));

    await handler.rewind();
    // 每次调用都基于最近一次发布的 PlaybackState（此处仍是 10s）。
    expect(target.seekedTo, Duration.zero);
  });

  test('快进不会越过曲目时长', () async {
    final _FakeTarget target = _FakeTarget();
    final AppAudioHandler handler = _buildHandler(target);
    handler.mediaItem.add(
      MediaItem(
        id: 'bvid:test:cid:1',
        title: 'P60',
        duration: const Duration(seconds: 20),
      ),
    );

    await handler.fastForward();

    expect(target.seekedTo, const Duration(seconds: 20));
  });

  test('发布的 PlaybackState 带快进快退按钮与进度时间戳', () {
    final AppAudioHandler handler = _buildHandler(_FakeTarget());

    final PlaybackState state = handler.playbackState.value;
    expect(
      state.controls.map((MediaControl control) => control.action).toList(),
      containsAll(<MediaAction>[
        MediaAction.rewind,
        MediaAction.fastForward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      ]),
    );
    expect(state.updatePosition, const Duration(seconds: 10));
    expect(state.queueIndex, 2);
    expect(state.updateTime, isNotNull);
  });
}
