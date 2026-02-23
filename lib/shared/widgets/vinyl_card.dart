import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';

class VinylCard extends ConsumerStatefulWidget {
  final SongModel song;
  final VoidCallback onTap;

  const VinylCard({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  ConsumerState<VinylCard> createState() => _VinylCardState();
}

class _VinylCardState extends ConsumerState<VinylCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // 10 secondes pour un tour complet
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentSong = playerState.currentSong?.id == widget.song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    // Gérer l'animation en fonction de l'état de lecture
    if (isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }

    return GestureDetector(
      onTap: () {
        if (isCurrentSong) {
          if (isPlaying) {
            ref.read(audioPlayerProvider.notifier).pause();
          } else {
            ref.read(audioPlayerProvider.notifier).resume();
          }
        } else {
          widget.onTap();
        }
      },
      child: Column(
        children: [
          // Vinyl Art
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotation du disque
                RotationTransition(
                  turns: _controller,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Disque noir de fond
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      // Pochette
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipOval(
                          child: AlbumArtImage(
                            albumArtPath: widget.song.albumArtPath,
                            songId: widget.song.id,
                            size: double.infinity,
                            fit: BoxFit.cover,
                            placeholderIcon: const Icon(Icons.music_note, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      // Trou central
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Overlay Play/Pause Button (ne tourne pas)
                if (isCurrentSong)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Info
          Text(
            widget.song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCurrentSong ? Theme.of(context).colorScheme.primary : null,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
