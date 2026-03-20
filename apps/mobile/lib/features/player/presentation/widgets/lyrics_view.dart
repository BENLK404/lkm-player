import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/lyrics_provider.dart';

class LyricsView extends ConsumerWidget {
  final SongModel song;
  final ValueNotifier<int> playbackTime;
  final Function(Duration)? onSeek;

  const LyricsView({
    super.key,
    required this.song,
    required this.playbackTime,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsAsync = ref.watch(lyricsProvider(song.id));

    return lyricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de lecture des paroles',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (lyricsContent) {
        if (lyricsContent == null || lyricsContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lyrics_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune parole disponible',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: playbackTime,
          builder: (context, position, child) {
            return LyricsReader(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              model: LyricsModelBuilder.create()
                  .bindLyricToMain(lyricsContent)
                  .getModel(),
              position: position,
              emptyBuilder: () => const Center(
                child: Text('Aucune parole disponible'),
              ),
              selectLineBuilder: onSeek != null
                  ? (progress, confirm) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lecture sélectionnée',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    _formatDuration(
                                      Duration(milliseconds: progress),
                                    ),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                onSeek?.call(Duration(milliseconds: progress));
                                confirm.call();
                              },
                              child: const Text('Lire'),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              lyricUi: UINetease(
                highlight: true,
                defaultSize: 16,
                defaultExtSize: 14,
                otherMainSize: 16,
                bias: 0.5,
                lineGap: 20,
                inlineGap: 10,
                lyricAlign: LyricAlign.CENTER,
                highlightDirection: HighlightDirection.LTR,
              ),
              onTap: onSeek != null ? () {} : null,
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
