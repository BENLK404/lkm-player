import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

import 'album_art_image.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final int songIndex;
  final VoidCallback? onLongPress;
  final bool showTrailingMenu;
  final Widget? trailing;
  final bool showIndex; // Nouveau paramètre

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    required this.songIndex,
    this.onLongPress,
    this.showTrailingMenu = true,
    this.trailing,
    this.showIndex = false, // Par défaut à false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = playerState.isPlaying && isCurrentSong;
    final isFavorite = ref.watch(musicProvider).asData?.value.songs.firstWhere((s) => s.id == song.id, orElse: () => song).isFavorite ?? song.isFavorite;

    return ListTile(
      leading: showIndex
          ? SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: isCurrentSong
                    ? Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Text(
                        '${songIndex + 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            )
          : AlbumArtImage(
              songId: song.id,
              albumArtPath: song.albumArtPath,
            ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
          color: isCurrentSong ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isCurrentSong
              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing ?? (showTrailingMenu
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(Duration(milliseconds: song.duration)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(context, ref, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_favorite',
                      child: Row(
                        children: [
                          Icon(isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border),
                          const SizedBox(width: 12),
                          Text(isFavorite
                              ? 'Retirer des favoris'
                              : 'Ajouter aux favoris'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'play_next',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music),
                          SizedBox(width: 12),
                          Text('Lire ensuite'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_to_queue',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add),
                          SizedBox(width: 12),
                          Text('Ajouter à la file'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_to_playlist',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_play),
                          SizedBox(width: 12),
                          Text('Ajouter à la playlist'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (song.albumId != null)
                      PopupMenuItem(
                        value: 'go_to_album',
                        child: Row(
                          children: [
                            const Icon(Icons.album),
                            const SizedBox(width: 12),
                            const Text('Aller à l\'album'),
                          ],
                        ),
                      ),
                    if (song.artistId != null)
                      PopupMenuItem(
                        value: 'go_to_artist',
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 12),
                            const Text('Aller à l\'artiste'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            )
          : Text(
              _formatDuration(Duration(milliseconds: song.duration)),
              style: Theme.of(context).textTheme.bodySmall,
            )),
      onTap: () => _playSong(ref),
      onLongPress: onLongPress,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _playSong(WidgetRef ref) {
    ref.read(audioPlayerProvider.notifier).play(playlist, songIndex);
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'toggle_favorite':
        ref.read(musicProvider.notifier).toggleFavoriteStatus(song);
        break;
      case 'play_next':
        ref.read(audioPlayerProvider.notifier).addNext(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} sera joué ensuite'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'add_to_queue':
        ref.read(audioPlayerProvider.notifier).addToQueue(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} ajouté à la file d\'attente'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(context, ref, song);
        break;
      case 'go_to_album':
        if (song.albumId != null) {
          context.push('/album/${song.albumId}');
        }
        break;
      case 'go_to_artist':
        if (song.artistId != null) {
          context.push('/artist/${song.artistId}');
        }
        break;
    }
  }

  void _showAddToPlaylistDialog(
      BuildContext context, WidgetRef ref, SongModel song) {
    final playlists = ref.read(musicProvider).asData?.value.playlists ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter à la playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    ref
                        .read(musicProvider.notifier)
                        .addSongToPlaylist(song.id, playlist.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${song.title} ajouté à ${playlist.name}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
