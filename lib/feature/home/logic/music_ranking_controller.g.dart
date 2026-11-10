// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_ranking_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biliMusicRankingRepository)
final biliMusicRankingRepositoryProvider =
    BiliMusicRankingRepositoryProvider._();

final class BiliMusicRankingRepositoryProvider
    extends
        $FunctionalProvider<
          BiliMusicRankingRepository,
          BiliMusicRankingRepository,
          BiliMusicRankingRepository
        >
    with $Provider<BiliMusicRankingRepository> {
  BiliMusicRankingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biliMusicRankingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biliMusicRankingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BiliMusicRankingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BiliMusicRankingRepository create(Ref ref) {
    return biliMusicRankingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiliMusicRankingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiliMusicRankingRepository>(value),
    );
  }
}

String _$biliMusicRankingRepositoryHash() =>
    r'ec0f5aba824dc1374d9f2a64eec9cd21cb9a3ae0';

@ProviderFor(MusicRankingController)
final musicRankingControllerProvider = MusicRankingControllerProvider._();

final class MusicRankingControllerProvider
    extends
        $AsyncNotifierProvider<MusicRankingController, List<MusicRankingItem>> {
  MusicRankingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicRankingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicRankingControllerHash();

  @$internal
  @override
  MusicRankingController create() => MusicRankingController();
}

String _$musicRankingControllerHash() =>
    r'7c6e8c7f50a5fd5b718d58a2de2e7be87948c361';

abstract class _$MusicRankingController
    extends $AsyncNotifier<List<MusicRankingItem>> {
  FutureOr<List<MusicRankingItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MusicRankingItem>>, List<MusicRankingItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MusicRankingItem>>,
                List<MusicRankingItem>
              >,
              AsyncValue<List<MusicRankingItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
