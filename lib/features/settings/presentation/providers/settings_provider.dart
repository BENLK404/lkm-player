import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@riverpod
class MinSongDuration extends _$MinSongDuration {
  late SharedPreferences _prefs;
  static const _key = 'min_song_duration';

  @override
  Future<int> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt(_key) ?? 10; // Valeur par défaut de 10 secondes
  }

  Future<void> setDuration(int seconds) async {
    state = AsyncValue.data(seconds);
    await _prefs.setInt(_key, seconds);
  }
}

@riverpod
class OnlineFeatureEnabled extends _$OnlineFeatureEnabled {
  late SharedPreferences _prefs;
  static const _key = 'online_feature_enabled';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true; // Activé par défaut
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncValue.data(enabled);
    await _prefs.setBool(_key, enabled);
  }
}

/// 0 = light, 1 = dark, 2 = system
@riverpod
class ThemeModeSetting extends _$ThemeModeSetting {
  late SharedPreferences _prefs;
  static const _key = 'theme_mode';

  @override
  Future<int> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt(_key) ?? 1; // 1 = dark par défaut
  }

  Future<void> setMode(int value) async {
    state = AsyncValue.data(value);
    await _prefs.setInt(_key, value);
  }
}

/// Durée par défaut du minuteur de sommeil en minutes (0 = désactivé).
@riverpod
class SleepTimerDefaultMinutes extends _$SleepTimerDefaultMinutes {
  late SharedPreferences _prefs;
  static const _key = 'sleep_timer_default_minutes';

  @override
  Future<int> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt(_key) ?? 0;
  }

  Future<void> setDefaultMinutes(int minutes) async {
    state = AsyncValue.data(minutes);
    await _prefs.setInt(_key, minutes);
  }
}

@riverpod
class ExcludeMessagingApps extends _$ExcludeMessagingApps {
  late SharedPreferences _prefs;
  static const _key = 'exclude_messaging_apps';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true; // true par défaut
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}
