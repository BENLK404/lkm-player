// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sleepTimerHash() => r'86c269bcb50b69ee6d471a5a4d392799c90bb509';

/// Nombre de secondes restantes avant arrêt (null = minuteur inactif).
///
/// Copied from [SleepTimer].
@ProviderFor(SleepTimer)
final sleepTimerProvider =
    AutoDisposeNotifierProvider<SleepTimer, int?>.internal(
  SleepTimer.new,
  name: r'sleepTimerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sleepTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SleepTimer = AutoDisposeNotifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
