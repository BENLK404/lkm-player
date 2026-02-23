import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/for_you/presentation/providers/for_you_filter_provider.dart';
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

          // Deriver les listes pour le tableau de bord
          
          // Ajouts récents : trier par date d'ajout
          final recentlyAdded = List<SongModel>.from(state.songs)
            ..sort((a, b) {
              final dateA = a.dateAdded ?? 0;
              final dateB = b.dateAdded ?? 0;
              return dateB.compareTo(dateA);
            });

          final recentlyPlayed =
              state.songs.where((s) => s.lastPlayed != null).toList()
                ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));

          final mostPlayed =
              state.songs.where((s) => s.playCount > 0).toList()
                ..sort((a, b) => b.playCount.compareTo(a.playCount));

          final favorites = state.songs.where((s) => s.isFavorite).toList();
          final playlists = state.playlists;

          // Grouper par genre (genre non vide)
          final byGenre = <String, List<SongModel>>{};
          for (final song in state.songs) {
            final g = song.genre?.trim();
            if (g != null && g.isNotEmpty) {
              byGenre.putIfAbsent(g, () => []).add(song);
            }
          }
          // Trier les genres par nombre de titres (décroissant)
          final genreEntries = byGenre.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          // Grouper par année (année non nulle)
          final byYear = <int, List<SongModel>>{};
          for (final song in state.songs) {
            final y = song.year;
            if (y != null && y > 0) {
              byYear.putIfAbsent(y, () => []).add(song);
            }
          }
          final yearEntries = byYear.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          // Grouper par artiste
          final byArtist = <String, List<SongModel>>{};
          for (final song in state.songs) {
            final a = song.artist.trim();
            if (a.isNotEmpty) {
              byArtist.putIfAbsent(a, () => []).add(song);
            }
          }
          final artistEntries = byArtist.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            children: [
              // Boutons Lecture aléatoire / Tous lire
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlayActionButton(
                        icon: Icons.shuffle_rounded,
                        label: 'Lecture aléatoire',
                        onTap: () {
                          final shuffled = List<SongModel>.from(state.songs)..shuffle();
                          if (shuffled.isNotEmpty) {
                            ref.read(audioPlayerProvider.notifier).play(shuffled, 0);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlayActionButton(
                        icon: Icons.playlist_play_rounded,
                        label: 'Tous lire',
                        onTap: () {
                          if (state.songs.isNotEmpty) {
                            ref.read(audioPlayerProvider.notifier).play(state.songs, 0);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tri et filtre + Tous les titres
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tous les titres',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final sort = ref.watch(forYouSortProvider);
                              return DropdownButtonFormField<ForYouSort>(
                                value: sort,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: ForYouSort.values
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) ref.read(forYouSortProvider.notifier).state = v;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final genre = ref.watch(forYouGenreFilterProvider);
                              final genreKeys = byGenre.keys.toList()..sort();
                              return DropdownButtonFormField<String>(
                                value: genre ?? 'Tous',
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                                  ...genreKeys.map((g) => DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) {
                                  ref.read(forYouGenreFilterProvider.notifier).state =
                                      (v == null || v == 'Tous') ? null : v;
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final sort = ref.watch(forYouSortProvider);
                  final genreFilter = ref.watch(forYouGenreFilterProvider);
                  var allFiltered = genreFilter == null || genreFilter.isEmpty
                      ? List<SongModel>.from(state.songs)
                      : state.songs.where((s) => s.genre?.trim() == genreFilter).toList();
                  switch (sort) {
                    case ForYouSort.title:
                      allFiltered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                      break;
                    case ForYouSort.artist:
                      allFiltered.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
                      break;
                    case ForYouSort.dateAdded:
                      allFiltered.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
                      break;
                    case ForYouSort.recentlyPlayed:
                      allFiltered = allFiltered.where((s) => s.lastPlayed != null).toList()
                        ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
                      break;
                    case ForYouSort.mostPlayed:
                      allFiltered = allFiltered.where((s) => s.playCount > 0).toList()
                        ..sort((a, b) => b.playCount.compareTo(a.playCount));
                      break;
                  }
                  final preview = allFiltered.take(20).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: preview.length,
                          itemBuilder: (context, index) {
                            final song = preview[index];
                            return SongTile(
                              song: song,
                              playlist: allFiltered,
                              songIndex: index,
                            );
                          },
                        ),
                        if (allFiltered.length > 20)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: () => _navigateToSongList(
                                  context,
                                  'Tous les titres',
                                  allFiltered,
                                ),
                                icon: const Icon(Icons.list),
                                label: Text('Voir tout (${allFiltered.length} titres)'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Par genre
              if (genreEntries.isNotEmpty) ...[
                _buildSectionHeader(context, 'Par genre'),
                ...genreEntries.map((e) {
                  final genreName = e.key;
                  final genreSongs = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                genreName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              InkWell(
                                onTap: () => _navigateToSongList(context, genreName, genreSongs),
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
                        ),
                        _buildHorizontalSongList(
                          context,
                          ref,
                          genreSongs.take(6).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Par année
              if (yearEntries.isNotEmpty) ...[
                _buildSectionHeader(context, 'Par année'),
                ...yearEntries.map((e) {
                  final year = e.key;
                  final yearSongs = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$year',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              InkWell(
                                onTap: () => _navigateToSongList(context, '$year', yearSongs),
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
                        ),
                        _buildHorizontalSongList(
                          context,
                          ref,
                          yearSongs.take(6).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Par artiste
              if (artistEntries.isNotEmpty) ...[
                _buildSectionHeader(context, 'Par artiste'),
                ...artistEntries.take(8).map((e) {
                  final artistName = e.key;
                  final artistSongs = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  artistName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () => _navigateToSongList(context, artistName, artistSongs),
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
                        ),
                        _buildHorizontalSongList(
                          context,
                          ref,
                          artistSongs.take(6).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Pour vous : Écoutez aussi (basé sur historique / genre / artiste)
              if (recentlyPlayed.isNotEmpty) ...[
                _buildSectionHeader(context, 'Écoutez aussi', showSeeAll: false),
                _buildListenAlsoSection(context, ref, state.songs, recentlyPlayed),
                const SizedBox(height: 24),
              ],

              // Artistes similaires (même genre que vos artistes les plus écoutés)
              if (mostPlayed.isNotEmpty && artistEntries.length > 1) ...[
                _buildSectionHeader(context, 'Artistes similaires', showSeeAll: false),
                _buildSimilarArtistsSection(context, ref, state.songs, mostPlayed, byArtist),
                const SizedBox(height: 24),
              ],

              // 1. Écoutés récemment (Priorité haute)
              if (recentlyPlayed.isNotEmpty) ...[
                _buildSectionHeader(
                  context, 
                  'Reprendre la lecture',
                  showSeeAll: true,
                  onTapSeeAll: () => _navigateToSongList(context, 'Écoutés récemment', recentlyPlayed),
                ),
                _buildHorizontalVinylList(
                  context, 
                  ref, 
                  recentlyPlayed.take(4).toList(), // Limité à 4
                ),
                const SizedBox(height: 32),
              ],

              // 2. Vos favoris (Accès rapide)
              if (favorites.isNotEmpty) ...[
                _buildSectionHeader(
                  context, 
                  'Vos coups de cœur', 
                  showSeeAll: true, 
                  onTapSeeAll: () => _navigateToSongList(context, 'Vos favoris', favorites),
                ),
                _buildVerticalSongList(ref, favorites.take(4).toList()), // Limité à 4
                const SizedBox(height: 32),
              ],

              // 3. Playlists (Organisation)
              if (playlists.isNotEmpty) ...[
                _buildSectionHeader(context, 'Vos playlists'),
                _buildHorizontalPlaylistList(context, ref, playlists.take(4).toList(), state.songs), // Limité à 4
                const SizedBox(height: 32),
              ],

              // 4. Ajouts récents (Découverte)
              _buildSectionHeader(
                context, 
                'Ajoutés récemment',
                showSeeAll: true,
                onTapSeeAll: () => _navigateToSongList(context, 'Ajoutés récemment', recentlyAdded),
              ),
              _buildHorizontalSongList(
                context, 
                ref, 
                recentlyAdded.take(4).toList(), // Limité à 4
              ),
              const SizedBox(height: 32),

              // 5. Les plus écoutés (Statistiques)
              if (mostPlayed.isNotEmpty) ...[
                _buildSectionHeader(
                  context, 
                  'Les plus écoutés',
                  showSeeAll: true,
                  onTapSeeAll: () => _navigateToSongList(context, 'Les plus écoutés', mostPlayed),
                ),
                _buildHorizontalSongList(
                  context, 
                  ref, 
                  mostPlayed.take(4).toList(), // Limité à 4
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

  void _navigateToSongList(BuildContext context, String title, List<SongModel> songs) {
    context.push(
      AppRouter.songList,
      extra: {'title': title, 'songs': songs},
    );
  }

  /// Suggestions basées sur les écoutes récentes (même genre / même artiste).
  Widget _buildListenAlsoSection(
    BuildContext context,
    WidgetRef ref,
    List<SongModel> allSongs,
    List<SongModel> recentlyPlayed,
  ) {
    final recentIds = recentlyPlayed.map((s) => s.id).toSet();
    final genres = recentlyPlayed.map((s) => s.genre?.trim()).whereType<String>().where((g) => g.isNotEmpty).toSet();
    final artists = recentlyPlayed.map((s) => s.artist.trim()).where((a) => a.isNotEmpty).toSet();

    final candidates = allSongs.where((s) {
      if (recentIds.contains(s.id)) return false;
      if (genres.isNotEmpty && s.genre != null && genres.contains(s.genre!.trim())) return true;
      if (artists.isNotEmpty && artists.contains(s.artist.trim())) return true;
      return false;
    }).toList();
    candidates.shuffle();
    final listenAlso = candidates.take(6).toList();
    if (listenAlso.isEmpty) return const SizedBox.shrink();
    return _buildHorizontalSongList(context, ref, listenAlso);
  }

  /// Artistes similaires (même genre que vos artistes les plus écoutés).
  Widget _buildSimilarArtistsSection(
    BuildContext context,
    WidgetRef ref,
    List<SongModel> allSongs,
    List<SongModel> mostPlayed,
    Map<String, List<SongModel>> byArtist,
  ) {
    if (byArtist.isEmpty) return const SizedBox.shrink();

    final artistPlayCount = <String, int>{};
    for (final s in mostPlayed) {
      final a = s.artist.trim();
      if (a.isNotEmpty) artistPlayCount[a] = (artistPlayCount[a] ?? 0) + s.playCount;
    }
    final topArtists = artistPlayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topNames = topArtists.take(3).map((e) => e.key).toSet();
    final topGenres = <String>{};
    for (final s in mostPlayed) {
      if (topNames.contains(s.artist.trim()) && s.genre != null && s.genre!.trim().isNotEmpty) {
        topGenres.add(s.genre!.trim());
      }
    }

    final otherArtists = byArtist.entries.where((e) {
      if (topNames.contains(e.key)) return false;
      final hasGenre = e.value.any((s) => s.genre != null && topGenres.contains(s.genre!.trim()));
      return topGenres.isEmpty || hasGenre;
    }).toList();
    final artistTotalPlays = <String, int>{};
    for (final e in otherArtists) {
      artistTotalPlays[e.key] = e.value.fold<int>(0, (sum, s) => sum + s.playCount);
    }
    otherArtists.sort((a, b) => (artistTotalPlays[b.key] ?? 0).compareTo(artistTotalPlays[a.key] ?? 0));
    final similar = otherArtists.take(6).toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: similar.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = similar[index];
          final name = entry.key;
          final songs = entry.value;
          final firstSong = songs.isNotEmpty ? songs.first : null;
          return SizedBox(
            width: 100,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToSongList(context, name, songs),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: firstSong != null
                          ? ClipOval(
                              child: AlbumArtImage(
                                albumArtPath: firstSong.albumArtPath,
                                songId: firstSong.id,
                                size: 72,
                                placeholderIcon: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ),
                            )
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showSeeAll = false, VoidCallback? onTapSeeAll}) {
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
      BuildContext context, WidgetRef ref, List<SongModel> songs, {bool showPlayCount = false}) {
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

  Widget _buildHorizontalPlaylistList(
      BuildContext context, WidgetRef ref, List<PlaylistModel> playlists, List<SongModel> allSongs) {
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
            final song = allSongs.firstWhere(
              (s) => s.id == songId, 
              orElse: () => const SongModel(id: '', title: '', artist: '', album: '', path: '', duration: 0)
            );
            if (song.id.isNotEmpty) {
              playlistSongs.add(song);
              totalDurationMs += song.duration;
              if (song.albumArtPath != null && !albumArtPaths.contains(song.albumArtPath)) {
                albumArtPaths.add(song.albumArtPath);
              }
            }
          }
          
          final durationText = _formatDuration(Duration(milliseconds: totalDurationMs));
          final details = '${playlist.songIds.length} titre${playlist.songIds.length > 1 ? 's' : ''} • $durationText';
          
          return SizedBox(
            width: 160,
            child: PlaylistCard(
              playlist: playlist.toAlbumModel(),
              details: details,
              albumArtPaths: albumArtPaths,
              onTap: () => context.push('/playlist/${playlist.id}'),
              onPlayTap: playlistSongs.isNotEmpty 
                ? () {
                    ref.read(audioPlayerProvider.notifier).play(playlistSongs, 0);
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

/// Bouton d'action de lecture (lecture aléatoire / tous lire).
class _PlayActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension pour convertir PlaylistModel en AlbumModel (affichage)
extension on PlaylistModel {
  AlbumModel toAlbumModel() {
    return AlbumModel(
      id: id,
      name: name,
      artist: '', // Sera remplacé par customSubtitle
      albumArtPath: null,
      year: dateCreated?.year,
      songIds: songIds,
      trackCount: songIds.length,
    );
  }
}
