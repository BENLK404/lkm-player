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
import 'package:musio/shared/widgets/vinyl_card.dart';

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

          // Total listen time in milliseconds
          final totalListenMs = state.songs.fold<int>(
            0,
            (sum, s) => sum + (s.playCount * s.duration),
          );

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
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            children: [
              // === TEMPS D'ÉCOUTE TOTAL ===
              if (totalListenMs > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _ListenTimeCard(totalMs: totalListenMs),
                ),

              // === EN COURS / REPRENDRE ===
              if (currentSong != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _NowPlayingCard(song: currentSong),
                )
              else if (recentlyPlayed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _ResumeLastCard(
                    song: recentlyPlayed.first,
                    onTap: () => ref
                        .read(audioPlayerProvider.notifier)
                        .play(recentlyPlayed, 0),
                  ),
                ),

              // === 5 DERNIERS MORCEAUX ÉCOUTÉS ===
              if (recentlyPlayed.isNotEmpty) ...[
                _buildSectionHeader(context, '5 derniers morceaux',
                    showSeeAll: recentlyPlayed.length > 5,
                    onTapSeeAll: () => _navigateToSongList(
                        context, 'Écoutés récemment', recentlyPlayed)),
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
                const SizedBox(height: 24),
              ],

              // === ARTISTES LES PLUS ÉCOUTÉS (16:9 mini banners) ===
              if (topArtistEntries.isNotEmpty) ...[
                _buildSectionHeader(context, 'Artistes favoris',
                    showSeeAll: false),
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
                const SizedBox(height: 28),
              ],

              // === REPRENDRE LA LECTURE (vinyl) ===
              if (recentlyPlayed.length > 1) ...[
                _buildSectionHeader(
                  context,
                  'Reprendre la lecture',
                  showSeeAll: true,
                  onTapSeeAll: () => _navigateToSongList(
                      context, 'Écoutés récemment', recentlyPlayed),
                ),
                _buildHorizontalVinylList(
                  context,
                  ref,
                  recentlyPlayed.skip(1).take(4).toList(),
                ),
                const SizedBox(height: 32),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          if (showSeeAll)
            InkWell(
              onTap: onTapSeeAll,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  'Voir tout',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildHorizontalVinylList(
      BuildContext context, WidgetRef ref, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final song = songs[index];
          return SizedBox(
            width: 130,
            child: VinylCard(
              song: song,
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

/// Card affichant le temps total d'écoute.
class _ListenTimeCard extends StatelessWidget {
  final int totalMs;

  const _ListenTimeCard({required this.totalMs});

  String _formatTotal(int ms) {
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.18), primary.withValues(alpha: 0.06)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temps d\'écoute total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTotal(totalMs),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.headphones_rounded, color: primary, size: 24),
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
          const _NowPlayingCardProgressBar(),
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

class _NowPlayingCardProgressBar extends ConsumerWidget {
  const _NowPlayingCardProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final position =
        ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration =
        ref.watch(audioPlayerProvider.select((s) => s.duration));
    final maxMs = duration.inMilliseconds;
    final value = maxMs > 0
        ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
        : 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      child: LinearProgressIndicator(
        value: maxMs > 0 ? value : 0,
        minHeight: 3,
        backgroundColor: scheme.outlineVariant.withValues(alpha: 0.28),
        color: scheme.primary.withValues(alpha: 0.85),
      ),
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
