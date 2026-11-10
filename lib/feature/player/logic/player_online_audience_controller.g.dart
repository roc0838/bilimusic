// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_online_audience_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerOnlineAudienceController)
final playerOnlineAudienceControllerProvider =
    PlayerOnlineAudienceControllerProvider._();

final class PlayerOnlineAudienceControllerProvider
    extends
        $AsyncNotifierProvider<
          PlayerOnlineAudienceController,
          PlayerOnlineAudience?
        > {
  PlayerOnlineAudienceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerOnlineAudienceControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerOnlineAudienceControllerHash();

  @$internal
  @override
  PlayerOnlineAudienceController create() => PlayerOnlineAudienceController();
}

String _$playerOnlineAudienceControllerHash() =>
    r'8a286f965b897d3fe99877e2afa11a7980f975d5';

abstract class _$PlayerOnlineAudienceController
    extends $AsyncNotifier<PlayerOnlineAudience?> {
  FutureOr<PlayerOnlineAudience?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PlayerOnlineAudience?>, PlayerOnlineAudience?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PlayerOnlineAudience?>,
                PlayerOnlineAudience?
              >,
              AsyncValue<PlayerOnlineAudience?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
