import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart'; // ✅ Nouveau widget

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push(AppRouter.nowPlaying),
      child: Container(
        height: 64, // Slightly shorter for Apple Music style
        margin: const EdgeInsets.only(
            bottom: 2, left: 8, right: 8), // Floating effect above bottom bar
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album Art
                    Hero(
                      tag: 'album-art-${currentSong.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AlbumArtImage(
                          albumArtPath: currentSong.albumArtPath,
                          songId: currentSong.id,
                          size: 40,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Song Info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            currentSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            if (playerState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).resume();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            ref.read(audioPlayerProvider.notifier).next();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Progress bar at the bottom
            LinearProgressIndicator(
              value: playerState.duration.inMilliseconds > 0
                  ? playerState.position.inMilliseconds /
                      playerState.duration.inMilliseconds
                  : 0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
