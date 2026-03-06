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
    final scheme = Theme.of(context).colorScheme;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final radius = BorderRadius.circular(16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRouter.nowPlaying),
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: SizedBox(
              height: 64,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'album-art-${currentSong.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AlbumArtImage(
                                albumArtPath: currentSong.albumArtPath,
                                songId: currentSong.id,
                                size: 40,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  playerState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 32,
                                  color: scheme.onSurface,
                                ),
                                onPressed: () {
                                  if (playerState.isPlaying) {
                                    ref
                                        .read(audioPlayerProvider.notifier)
                                        .pause();
                                  } else {
                                    ref
                                        .read(audioPlayerProvider.notifier)
                                        .resume();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  size: 32,
                                  color: scheme.onSurface,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: LinearProgressIndicator(
                      value: playerState.duration.inMilliseconds > 0
                          ? playerState.position.inMilliseconds /
                              playerState.duration.inMilliseconds
                          : 0,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.primary.withValues(alpha: 0.85),
                      ),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
