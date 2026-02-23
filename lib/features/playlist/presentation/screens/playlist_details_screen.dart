import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/playlist/data/system_playlist.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class PlaylistDetailsScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailsScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final isSystem = SystemPlaylist.isSystemId(playlistId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSystem ? SystemPlaylist.titleFor(playlistId) : 'Playlist'),
        actions: [
          if (!isSystem)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmationDialog(context, ref, playlistId);
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
      ),
      body: musicState.when(
        data: (state) {
          final List<SongModel> songs = isSystem
              ? _songsForSystemPlaylist(playlistId, state.songs)
              : _songsForUserPlaylist(playlistId, state.playlists, state.songs);
          final String title = isSystem
              ? SystemPlaylist.titleFor(playlistId)
              : state.playlists
                    .firstWhere(
                      (p) => p.id == playlistId,
                      orElse: () => PlaylistModel(id: '', name: 'Playlist', songIds: []),
                    )
                    .name;

          return Column(
            children: [
              _buildHeader(context, title, songs, ref),
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(
                          isSystem ? 'Aucun titre pour l\'instant.' : 'Cette playlist est vide.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return SongTile(
                            song: song,
                            playlist: songs,
                            songIndex: index,
                            showTrailingMenu: false,
                            trailing: isSystem && playlistId == SystemPlaylist.favorites
                                ? IconButton(
                                    icon: const Icon(Icons.favorite),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () {
                                      ref.read(musicProvider.notifier).toggleFavoriteStatus(song);
                                    },
                                  )
                                : isSystem
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          ref
                                              .read(musicProvider.notifier)
                                              .removeSongFromPlaylist(song.id, playlistId);
                                        },
                                      ),
                          );
                        },
                      ),
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

  List<SongModel> _songsForSystemPlaylist(String systemId, List<SongModel> allSongs) {
    return switch (systemId) {
      SystemPlaylist.favorites => allSongs.where((s) => s.isFavorite).toList(),
      SystemPlaylist.recent => allSongs
          .where((s) => s.lastPlayed != null)
          .toList()
        ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!)),
      SystemPlaylist.mostPlayed => allSongs
          .where((s) => s.playCount > 0)
          .toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount)),
      _ => [],
    };
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

  Widget _buildHeader(BuildContext context, String title,
      List<SongModel> songs, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('${songs.length} chanson${songs.length != 1 ? 's' : ''}'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: songs.isEmpty
                ? null
                : () {
                    ref.read(audioPlayerProvider.notifier).play(songs, 0);
                  },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lire tout'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, String playlistId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la playlist ?'),
        content:
            const Text('Cette action est irréversible.'),
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
