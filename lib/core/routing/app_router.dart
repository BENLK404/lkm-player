import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/album/presentation/screens/album_details_screen.dart';
import 'package:musio/features/artist/presentation/screens/artist_details_screen.dart';
import 'package:musio/features/home/presentation/screens/home_screen.dart';
import 'package:musio/features/home/presentation/screens/splash_screen.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/online/presentation/screens/online_screen.dart';
import 'package:musio/features/player/presentation/screens/now_playing_screen.dart';
import 'package:musio/features/playlist/presentation/screens/playlist_details_screen.dart';
import 'package:musio/features/search/presentation/screens/search_screen.dart';
import 'package:musio/features/settings/presentation/screens/about_screen.dart';
import 'package:musio/features/settings/presentation/screens/settings_screen.dart';
import 'package:musio/features/settings/presentation/screens/stats_screen.dart';
import 'package:musio/shared/screens/song_list_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String online = '/online';
  static const String nowPlaying = '/now-playing';
  static const String albumDetails = '/album/:id';
  static const String artistDetails = '/artist/:id';
  static const String playlistDetails = '/playlist/:id';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String about = '/settings/about';
  static const String stats = '/settings/stats';
  static const String songList = '/song-list';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash Screen (Initial Route)
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Home (Offline)
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OfflineHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Online
      GoRoute(
        path: online,
        name: 'online',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnlineScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Settings
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        routes: [
          GoRoute(
            path: 'stats',
            name: 'stats',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StatsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: 'about',
            name: 'about',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AboutScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ],
      ),

      // Song List (Generic)
      GoRoute(
        path: songList,
        name: 'song-list',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic> ||
              extra['title'] is! String ||
              extra['songs'] is! List) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Paramètres invalides',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go(home),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            );
          }
          return SongListScreen(
            title: extra['title'] as String,
            songs: List<SongModel>.from(extra['songs'] as List),
          );
        },
      ),

      // Now Playing
      GoRoute(
        path: nowPlaying,
        name: 'now-playing',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NowPlayingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Album Details
      GoRoute(
        path: albumDetails,
        name: 'album-details',
        pageBuilder: (context, state) {
          final albumId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AlbumDetailsScreen(albumId: albumId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Artist Details
      GoRoute(
        path: artistDetails,
        name: 'artist-details',
        pageBuilder: (context, state) {
          final artistId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ArtistDetailsScreen(artistId: artistId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Playlist Details
      GoRoute(
        path: playlistDetails,
        name: 'playlist-details',
        pageBuilder: (context, state) {
          final playlistId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaylistDetailsScreen(playlistId: playlistId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Search
      GoRoute(
        path: search,
        name: 'search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}
