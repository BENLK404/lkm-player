import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musio/core/providers/app_providers.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/core/theme/app_theme.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/player/data/models/saved_player_state.dart';
import 'package:musio/features/player/data/services/audio_handler.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer les adapters Hive
  Hive.registerAdapter(SongModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  Hive.registerAdapter(SavedPlayerStateAdapter());

  // Ouvrir les box Hive
  await Hive.openBox<SongModel>('songs');
  await Hive.openBox<PlaylistModel>('playlists');
  await Hive.openBox<SavedPlayerState>('player_state');
  await Hive.openBox('lyrics_cache');

  // Initialiser le service audio
  final audioHandler = await AudioService.init(
    builder: () => MusioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MusioApp(),
    ),
  );
}

class MusioApp extends ConsumerWidget {
  const MusioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeSettingProvider);

    return themeModeAsync.when(
      data: (modeIndex) {
        final themeMode = switch (modeIndex) {
          0 => ThemeMode.light,
          1 => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp.router(
          title: 'LKM Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
        );
      },
      loading: () => MaterialApp.router(
        title: 'LKM Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
      error: (_, __) => MaterialApp.router(
        title: 'LKM Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
