import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/playlist/data/system_playlist.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';
import 'package:palette_generator/palette_generator.dart';

class PlaylistDetailsScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailsScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailsScreen> createState() =>
      _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends ConsumerState<PlaylistDetailsScreen> {
  Color? dominantColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDominantColor();
    });
  }

  Future<void> _loadDominantColor() async {
    final musicState = ref.read(musicProvider);
    musicState.whenData((state) {
      final isSystem = SystemPlaylist.isSystemId(widget.playlistId);
      final songs = isSystem
          ? _songsForSystemPlaylist(widget.playlistId, state.songs)
          : _songsForUserPlaylist(
              widget.playlistId, state.playlists, state.songs);

      if (songs.isNotEmpty) {
        // Try to find the first song with an album art to get a color
        final firstSongWithArt = songs.cast<SongModel?>().firstWhere(
            (s) => s != null && s.albumArtPath != null,
            orElse: () => null);

        if (firstSongWithArt != null && firstSongWithArt.albumArtPath != null) {
          final imageProvider = FileImage(File(firstSongWithArt.albumArtPath!));
          PaletteGenerator.fromImageProvider(
            imageProvider,
            maximumColorCount: 10,
          ).then((palette) {
            if (mounted) {
              setState(() {
                dominantColor = palette.dominantColor?.color ??
                    palette.vibrantColor?.color ??
                    palette.mutedColor?.color;
              });
            }
          }).catchError((_) {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);
    final isSystem = SystemPlaylist.isSystemId(widget.playlistId);

    // Apply the diluted solid color background
    final backgroundColor = dominantColor != null
        ? Color.lerp(
            Theme.of(context).scaffoldBackgroundColor, dominantColor!, 0.15)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: musicState.when(
        data: (state) {
          final List<SongModel> songs = isSystem
              ? _songsForSystemPlaylist(widget.playlistId, state.songs)
              : _songsForUserPlaylist(
                  widget.playlistId, state.playlists, state.songs);
          final String title = isSystem
              ? SystemPlaylist.titleFor(widget.playlistId)
              : state.playlists
                  .firstWhere(
                    (p) => p.id == widget.playlistId,
                    orElse: () =>
                        PlaylistModel(id: '', name: 'Playlist', songIds: []),
                  )
                  .name;

          return CustomScrollView(
            slivers: [
              // En-tête immersif
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                stretch: true,
                backgroundColor: backgroundColor,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (!isSystem)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmationDialog(
                              context, ref, widget.playlistId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Supprimer la playlist',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fond uni basé sur la couleur dominante
                      Container(color: backgroundColor),

                      // Contenu de l'en-tête
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                height: 40), // Espace pour la status bar
                            // Pochette de la playlist (Mosaïque ou image du premier son)
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPlaylistCover(isSystem, songs),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Titre de la playlist
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Informations et Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Métadonnées
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${songs.length} titres',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bouton Lecture
                          Expanded(
                            child: ElevatedButton(
                              onPressed: songs.isEmpty
                                  ? null
                                  : () {
                                      ref
                                          .read(audioPlayerProvider.notifier)
                                          .play(songs, 0);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded),
                                  SizedBox(width: 8),
                                  Text('Lecture',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Bouton Aléatoire
                          Expanded(
                            child: OutlinedButton(
                              onPressed: songs.isEmpty
                                  ? null
                                  : () {
                                      ref
                                          .read(audioPlayerProvider.notifier)
                                          .play(songs, 0);
                                      ref
                                          .read(audioPlayerProvider.notifier)
                                          .toggleShuffle();
                                    },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shuffle_rounded),
                                  SizedBox(width: 8),
                                  Text('Aléatoire',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Liste des chansons
              if (songs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      isSystem
                          ? 'Aucun titre pour l\'instant.'
                          : 'Cette playlist est vide.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: Colors.white,
                                displayColor: Colors.white,
                              ),
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        child: SongTile(
                          song: song,
                          playlist: songs,
                          songIndex: index,
                          showTrailingMenu: false,
                          trailing: isSystem &&
                                  widget.playlistId == SystemPlaylist.favorites
                              ? IconButton(
                                  icon: const Icon(Icons.favorite),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary, // Apple music pink
                                  onPressed: () {
                                    ref
                                        .read(musicProvider.notifier)
                                        .toggleFavoriteStatus(song);
                                  },
                                )
                              : isSystem
                                  ? null
                                  : IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.white70),
                                      onPressed: () {
                                        ref
                                            .read(musicProvider.notifier)
                                            .removeSongFromPlaylist(
                                                song.id, widget.playlistId);
                                      },
                                    ),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),

              // Espace pour le mini player
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _buildPlaylistCover(bool isSystem, List<SongModel> songs) {
    if (isSystem) {
      IconData iconData;
      Color color;
      switch (widget.playlistId) {
        case SystemPlaylist.favorites:
          iconData = Icons.favorite;
          color = Colors.pink;
          break;
        case SystemPlaylist.recent:
          iconData = Icons.history;
          color = Colors.blue;
          break;
        case SystemPlaylist.mostPlayed:
          iconData = Icons.play_circle_filled;
          color = Colors.purple;
          break;
        default:
          iconData = Icons.queue_music;
          color = Colors.grey;
      }
      return Container(
        color: color.withOpacity(0.2),
        child: Icon(iconData, size: 80, color: color),
      );
    } else {
      // Pour une playlist utilisateur, on affiche la pochette de la première chanson
      if (songs.isNotEmpty) {
        final firstSongWithArt = songs.cast<SongModel?>().firstWhere(
            (s) => s != null && s.albumArtPath != null,
            orElse: () => null);
        if (firstSongWithArt != null) {
          return AlbumArtImage(
            songId: firstSongWithArt.id,
            albumArtPath: firstSongWithArt.albumArtPath,
            size: 180,
            fit: BoxFit.cover,
          );
        }
      }
      return const Icon(Icons.music_note, size: 80, color: Colors.grey);
    }
  }

  List<SongModel> _songsForSystemPlaylist(
      String systemId, List<SongModel> allSongs) {
    switch (systemId) {
      case SystemPlaylist.favorites:
        return allSongs.where((s) => s.isFavorite).toList();
      case SystemPlaylist.recent:
        final recent = allSongs.where((s) => s.lastPlayed != null).toList();
        recent.sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
        return recent;
      case SystemPlaylist.mostPlayed:
        final mostPlayed = allSongs.where((s) => s.playCount > 0).toList();
        mostPlayed.sort((a, b) => b.playCount.compareTo(a.playCount));
        return mostPlayed;
      default:
        return [];
    }
  }

  List<SongModel> _songsForUserPlaylist(
    String playlistId,
    List<PlaylistModel> playlists,
    List<SongModel> allSongs,
  ) {
    try {
      final playlist = playlists.firstWhere((p) => p.id == playlistId);
      return allSongs.where((s) => playlist.songIds.contains(s.id)).toList();
    } catch (_) {
      return [];
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, String playlistId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la playlist ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(musicProvider.notifier).deletePlaylist(playlistId);
              // Revenir à l'écran d'accueil après suppression
              context.go('/');
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
