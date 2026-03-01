// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioPlayerServiceHash() =>
    r'4fbe34bf29cfd07e91f054a0231baea70bfe1935';

/// Provider singleton pour le service audio
///
/// Copied from [audioPlayerService].
@ProviderFor(audioPlayerService)
final audioPlayerServiceProvider = Provider<AudioPlayerService>.internal(
  audioPlayerService,
  name: r'audioPlayerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AudioPlayerServiceRef = ProviderRef<AudioPlayerService>;
String _$audioPlayerHash() => r'72ce2850ab263a4a32b8849d379e7919295dcbb1';

/// See also [AudioPlayer].
@ProviderFor(AudioPlayer)
final audioPlayerProvider = NotifierProvider<AudioPlayer, PlayerState>.internal(
  AudioPlayer.new,
  name: r'audioPlayerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$audioPlayerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AudioPlayer = Notifier<PlayerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
