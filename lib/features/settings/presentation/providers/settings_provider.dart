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
    return _prefs.getInt(_key) ?? 10;
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
    return _prefs.getBool(_key) ?? true;
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
    return _prefs.getInt(_key) ?? 1;
  }

  Future<void> setMode(int value) async {
    state = AsyncValue.data(value);
    await _prefs.setInt(_key, value);
  }
}

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

// ─── Filtres apps de messagerie

/// Toggle global : active/désactive tous les filtres messagerie d'un coup.
@riverpod
class ExcludeMessagingApps extends _$ExcludeMessagingApps {
  late SharedPreferences _prefs;
  static const _key = 'exclude_messaging_apps';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// WhatsApp — exclu par défaut
@riverpod
class ExcludeWhatsApp extends _$ExcludeWhatsApp {
  late SharedPreferences _prefs;
  static const _key = 'exclude_whatsapp';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Telegram — inclus par défaut (bots musicaux)
@riverpod
class ExcludeTelegram extends _$ExcludeTelegram {
  late SharedPreferences _prefs;
  static const _key = 'exclude_telegram';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Signal — exclu par défaut
@riverpod
class ExcludeSignal extends _$ExcludeSignal {
  late SharedPreferences _prefs;
  static const _key = 'exclude_signal';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Viber — exclu par défaut
@riverpod
class ExcludeViber extends _$ExcludeViber {
  late SharedPreferences _prefs;
  static const _key = 'exclude_viber';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Discord — exclu par défaut
@riverpod
class ExcludeDiscord extends _$ExcludeDiscord {
  late SharedPreferences _prefs;
  static const _key = 'exclude_discord';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Autres apps (Skype, Line, WeChat, Snapchat, Slack…) — exclu par défaut
@riverpod
class ExcludeOtherMessaging extends _$ExcludeOtherMessaging {
  late SharedPreferences _prefs;
  static const _key = 'exclude_other_messaging';

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    await _prefs.setBool(_key, value);
  }
}

/// Couleur d'accentuation choisie par l'utilisateur (index 0–4).
/// 0 = Teal (défaut), 1 = Rouge, 2 = Jaune, 3 = Violet, 4 = Orange
@riverpod
class AccentColorSetting extends _$AccentColorSetting {
  late SharedPreferences _prefs;
  static const _key = 'accent_color_index';

  @override
  Future<int> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt(_key) ?? 0;
  }

  Future<void> setColorIndex(int index) async {
    state = AsyncValue.data(index);
    await _prefs.setInt(_key, index);
  }
}

/// URL de base de l'API Telegramusic.
/// Défaut utilisé si l'utilisateur n'a rien configuré dans Paramètres.
const String kDownloadApiBaseUrlDefault = 'https://lkm.emmanuekebeh.dev';

@riverpod
class DownloadApiBaseUrl extends _$DownloadApiBaseUrl {
  late SharedPreferences _prefs;
  static const _key = 'download_api_base_url';

  @override
  Future<String> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString(_key) ?? kDownloadApiBaseUrlDefault;
  }

  Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    state = AsyncValue.data(trimmed);
    await _prefs.setString(_key, trimmed);
  }
}
