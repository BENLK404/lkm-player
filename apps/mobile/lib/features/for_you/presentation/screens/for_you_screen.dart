import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/playlist_card.dart';
import 'package:musio/shared/widgets/song_card.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class ForYouScreen extends ConsumerWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);

    return Scaffold(
      body: musicState.when(
        data: (state) {
          if (state.songs.isEmpty) {
            return const Center(
                child: Text('Aucune musique dans la bibliothèque.'));
          }

          final recentlyAdded = List<SongModel>.from(state.songs)
            ..sort((a, b) {
              final dateA = a.dateAdded ?? 0;
              final dateB = b.dateAdded ?? 0;
              return dateB.compareTo(dateA);
            });

          final recentlyPlayed = state.songs
              .where((s) => s.lastPlayed != null)
              .toList()
            ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));

          final mostPlayed = state.songs.where((s) => s.playCount > 0).toList()
            ..sort((a, b) => b.playCount.compareTo(a.playCount));

          final favorites = state.songs.where((s) => s.isFavorite).toList();
          final playlists = state.playlists;

          // Artiste le plus écouté (basé sur le total des playCount)
          final artistTotalPlayCount = <String, int>{};
          final byArtist = <String, List<SongModel>>{};
          for (final song in state.songs) {
            final a = song.artist.trim();
            if (a.isNotEmpty) {
              byArtist.putIfAbsent(a, () => []).add(song);
              if (song.playCount > 0) {
                artistTotalPlayCount[a] =
                    (artistTotalPlayCount[a] ?? 0) + song.playCount;
              }
            }
          }

          // Top artists by playcount, if none then by song count
          final List<MapEntry<String, List<SongModel>>> topArtistEntries;
          if (artistTotalPlayCount.isNotEmpty) {
            final sorted = artistTotalPlayCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            topArtistEntries = sorted
                .take(5)
                .map((e) => MapEntry(e.key, byArtist[e.key]!))
                .toList();
          } else {
            final sorted = byArtist.entries.toList()
              ..sort((a, b) => b.value.length.compareTo(a.value.length));
            topArtistEntries = sorted.take(5).toList();
          }

          // Current audio player state
          final playerState = ref.watch(audioPlayerProvider);
          final currentSong = playerState.currentSong;

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              // === EN COURS / REPRENDRE (pas de barre de progression : voir mini lecteur) ===
              if (currentSong != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _NowPlayingCard(song: currentSong),
                )
              else if (recentlyPlayed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _ResumeLastCard(
                    song: recentlyPlayed.first,
                    onTap: () => ref
                        .read(audioPlayerProvider.notifier)
                        .play(recentlyPlayed, 0),
                  ),
                ),

              // === ÉCOUTÉS RÉCEMMENT (liste — la section vinyles a été retirée, doublon) ===
              if (recentlyPlayed.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Écoutés récemment',
                  showSeeAll: recentlyPlayed.length > 5,
                  onTapSeeAll: () => _navigateToSongList(
                    context,
                    'Écoutés récemment',
                    recentlyPlayed,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentlyPlayed.take(5).length,
                    itemBuilder: (context, index) {
                      final song = recentlyPlayed[index];
                      return SongTile(
                        song: song,
                        playlist: recentlyPlayed,
                        songIndex: index,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // === ARTISTES LES PLUS ÉCOUTÉS (16:9 mini banners) ===
              if (topArtistEntries.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Artistes favoris',
                  showSeeAll: false,
                ),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: topArtistEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final entry = topArtistEntries[index];
                      return SizedBox(
                        width: 220,
                        child: _SmallArtistBanner(
                          artistName: entry.key,
                          songs: entry.value,
                          onTap: () => _navigateToSongList(
                              context, entry.key, entry.value),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // === VOS COUPS DE CŒUR ===
              if (favorites.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Vos coups de cœur',
                  showSeeAll: true,
                  onTapSeeAll: () =>
                      _navigateToSongList(context, 'Vos favoris', favorites),
                ),
                _buildVerticalSongList(ref, favorites.take(4).toList()),
                const SizedBox(height: 32),
              ],

              // === PLAYLISTS ===
              if (playlists.isNotEmpty) ...[
                _buildSectionHeader(context, 'Vos playlists'),
                _buildHorizontalPlaylistList(
                    context, ref, playlists.take(4).toList(), state.songs),
                const SizedBox(height: 32),
              ],

              // === AJOUTÉS RÉCEMMENT ===
              _buildSectionHeader(
                context,
                'Ajoutés récemment',
                showSeeAll: true,
                onTapSeeAll: () => _navigateToSongList(
                    context, 'Ajoutés récemment', recentlyAdded),
              ),
              _buildHorizontalSongList(
                context,
                ref,
                recentlyAdded.take(4).toList(),
              ),
              const SizedBox(height: 32),

              // === LES PLUS ÉCOUTÉS ===
              if (mostPlayed.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Les plus écoutés',
                  showSeeAll: true,
                  onTapSeeAll: () => _navigateToSongList(
                      context, 'Les plus écoutés', mostPlayed),
                ),
                _buildHorizontalSongList(
                  context,
                  ref,
                  mostPlayed.take(4).toList(),
                  showPlayCount: true,
                ),
                const SizedBox(height: 32),
              ],

              const SizedBox(height: 80), // Espace pour le mini player
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  void _navigateToSongList(
      BuildContext context, String title, List<SongModel> songs) {
    context.push(
      AppRouter.songList,
      extra: {'title': title, 'songs': songs},
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {bool showSeeAll = false, VoidCallback? onTapSeeAll}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onTapSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tout voir',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSongList(
      BuildContext context, WidgetRef ref, List<SongModel> songs,
      {bool showPlayCount = false}) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = songs[index];
          Widget? subtitleWidget;

          if (showPlayCount) {
            subtitleWidget = Row(
              children: [
                Icon(
                  Icons.headset,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${song.playCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                ),
              ],
            );
          }

          return SizedBox(
            width: 140,
            child: SongCard(
              song: song,
              subtitleWidget: subtitleWidget,
              onTap: () {
                ref.read(audioPlayerProvider.notifier).play(songs, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalPlaylistList(BuildContext context, WidgetRef ref,
      List<PlaylistModel> playlists, List<SongModel> allSongs) {
    if (playlists.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final playlist = playlists[index];

          int totalDurationMs = 0;
          final playlistSongs = <SongModel>[];
          final albumArtPaths = <String?>[];

          for (var songId in playlist.songIds) {
            final song = allSongs.firstWhere((s) => s.id == songId,
                orElse: () => const SongModel(
                    id: '',
                    title: '',
                    artist: '',
                    album: '',
                    path: '',
                    duration: 0));
            if (song.id.isNotEmpty) {
              playlistSongs.add(song);
              totalDurationMs += song.duration;
              if (song.albumArtPath != null &&
                  !albumArtPaths.contains(song.albumArtPath)) {
                albumArtPaths.add(song.albumArtPath);
              }
            }
          }

          final durationText =
              _formatDuration(Duration(milliseconds: totalDurationMs));
          final details =
              '${playlist.songIds.length} titre${playlist.songIds.length > 1 ? 's' : ''} • $durationText';

          return SizedBox(
            width: 160,
            child: PlaylistCard(
              playlist: playlist.toAlbumModel(),
              details: details,
              albumArtPaths: albumArtPaths,
              onTap: () => context.push('/playlist/${playlist.id}'),
              onPlayTap: playlistSongs.isNotEmpty
                  ? () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .play(playlistSongs, 0);
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalSongList(WidgetRef ref, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            playlist: songs,
            songIndex: index,
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}

/// Salutation + résumé de la bibliothèque (données utiles, sans texte générique).
class _ForYouHeader extends StatelessWidget {
  const _ForYouHeader({
    required this.trackCount,
    required this.albumCount,
    required this.playlistCount,
    required this.favoritesCount,
  });

  final int trackCount;
  final int albumCount;
  final int playlistCount;
  final int favoritesCount;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Bonne nuit';
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weekday = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ][DateTime.now().weekday - 1];
    final day = DateTime.now().day;
    final month = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ][DateTime.now().month - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$weekday $day $month',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LibStatChip(
                icon: Icons.music_note_rounded,
                value: trackCount,
                label: trackCount > 1 ? 'titres' : 'titre',
                scheme: scheme,
              ),
              _LibStatChip(
                icon: Icons.album_rounded,
                value: albumCount,
                label: albumCount > 1 ? 'albums' : 'album',
                scheme: scheme,
              ),
              _LibStatChip(
                icon: Icons.playlist_play_rounded,
                value: playlistCount,
                label: playlistCount > 1 ? 'playlists' : 'playlist',
                scheme: scheme,
              ),
              if (favoritesCount > 0)
                _LibStatChip(
                  icon: Icons.favorite_rounded,
                  value: favoritesCount,
                  label: favoritesCount > 1 ? 'favoris' : 'favori',
                  scheme: scheme,
                  iconColor: scheme.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibStatChip extends StatelessWidget {
  const _LibStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.scheme,
    this.iconColor,
  });

  final IconData icon;
  final int value;
  final String label;
  final ColorScheme scheme;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: ic),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Card « En cours » — pochette + infos ouvrent l’écran lecture ; contrôles séparés.
class _NowPlayingCard extends ConsumerWidget {
  final SongModel song;

  const _NowPlayingCard({required this.song});

  void _openNowPlaying(BuildContext context) {
    context.push(AppRouter.nowPlaying);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openNowPlaying(context),
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AlbumArtImage(
                        albumArtPath: song.albumArtPath,
                        songId: song.id,
                        size: 76,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openNowPlaying(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.equalizer_rounded,
                                    size: 14,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'En cours de lecture',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const _NowPlayingQuickControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Play / pause + suivant (ne ouvre pas l’écran plein écran).
class _NowPlayingQuickControls extends ConsumerWidget {
  const _NowPlayingQuickControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final isPlaying =
        ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final notifier = ref.read(audioPlayerProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: () {
              if (isPlaying) {
                notifier.pause();
              } else {
                notifier.resume();
              }
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 50,
              height: 50,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(isPlaying),
                  color: onPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => notifier.next(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.skip_next_rounded,
                size: 24,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card « Reprendre » — même famille visuelle que la carte en cours.
class _ResumeLastCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;

  const _ResumeLastCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AlbumArtImage(
                  albumArtPath: song.albumArtPath,
                  songId: song.id,
                  size: 76,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Reprendre',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: onPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini bannière 16:9 pour un artiste (style Apple Music, plus petite).
class _SmallArtistBanner extends StatelessWidget {
  final String artistName;
  final List<SongModel> songs;
  final VoidCallback onTap;

  const _SmallArtistBanner({
    required this.artistName,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final songWithArt = songs.firstWhere(
      (s) => s.albumArtPath != null,
      orElse: () => songs.first,
    );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildArt(songWithArt),
              // Dark gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.2, 1.0],
                    colors: [Colors.transparent, Color(0xD0000000)],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Text(
                  artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArt(SongModel song) {
    final path = song.albumArtPath;
    if (path == null) return _placeholder();
    if (path.startsWith('content://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C2A3A), Color(0xFF0D1117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

// Extension pour convertir PlaylistModel en AlbumModel (affichage)
extension on PlaylistModel {
  AlbumModel toAlbumModel() {
    return AlbumModel(
      id: id,
      name: name,
      artist: '',
      albumArtPath: null,
      year: dateCreated?.year,
      songIds: songIds,
      trackCount: songIds.length,
    );
  }
}
