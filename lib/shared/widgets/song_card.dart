import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';

class SongCard extends ConsumerWidget {
  final SongModel song;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? subtitleWidget;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.subtitle,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return GestureDetector(
      onTap: () {
        if (isCurrentSong) {
          if (isPlaying) {
            ref.read(audioPlayerProvider.notifier).pause();
          } else {
            ref.read(audioPlayerProvider.notifier).resume();
          }
        } else {
          onTap();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song Art
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AlbumArtImage(
                      albumArtPath: song.albumArtPath,
                      songId: song.id,
                      size: double.infinity,
                      borderRadius: BorderRadius.zero,
                      fit: BoxFit.cover,
                      placeholderIcon: const Icon(Icons.music_note, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                // Overlay Play/Pause Button - Réduit de moitié
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 16, // Réduit à 16px
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 10, // Réduit à 10px
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentSong ? Theme.of(context).colorScheme.primary : null,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 2),
                if (subtitleWidget != null)
                  subtitleWidget!
                else
                  Text(
                    subtitle ?? song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 10,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
