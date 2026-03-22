import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'audio_player_provider.dart';

part 'sleep_timer_provider.g.dart';

/// Nombre de secondes restantes avant arrêt (null = minuteur inactif).
@riverpod
class SleepTimer extends _$SleepTimer {
  Timer? _timer;

  @override
  int? build() => null;

  void start(int minutes) {
    _timer?.cancel();
    if (minutes <= 0) {
      state = null;
      return;
    }
    state = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state;
      if (remaining == null || remaining <= 1) {
        _timer?.cancel();
        _timer = null;
        state = null;
        ref.read(audioPlayerProvider.notifier).pause();
        return;
      }
      state = remaining - 1;
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}
