import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

/// Mini lecteur : barre de progression en bas (fixe ou [seekableProgress] pour glisser).
/// File d’attente, « à suivre », lecture / pause.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    /// Si true : [Slider] sous le bloc principal — la position audio (et les paroles) suivent le geste.
    this.seekableProgress = false,
  });

  final bool seekableProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;
    final scheme = Theme.of(context).colorScheme;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final q = playerState.queue;
    final i = playerState.currentIndex;
    final nextSong = (q.isNotEmpty && i >= 0 && i < q.length - 1)
        ? q[i + 1]
        : null;
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            borderRadius: radius,
          ),
          child: SizedBox(
            height: seekableProgress ? 82 : 70,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 4),
                    child: Row(
                      children: [
                        // File d’attente (remplace la cover dupliquée)
                        Material(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push(AppRouter.queue),
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: scheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tap → plein écran ; ligne du bas = à suivre
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push(AppRouter.nowPlaying),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentSong.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      nextSong != null
                                          ? 'À suivre · ${nextSong.title}'
                                          : 'À suivre · fin de la file',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
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
                        // Seul contrôle rapide : lecture / pause (suivant : carte du haut ou file)
                        IconButton(
                          style: IconButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                          ),
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 40,
                            color: scheme.primary,
                          ),
                          onPressed: () {
                            if (playerState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).resume();
                            }
                          },
                          tooltip: playerState.isPlaying ? 'Pause' : 'Lecture',
                        ),
                      ],
                    ),
                  ),
                ),
                if (seekableProgress)
                  _SeekableProgressStrip(
                    scheme: scheme,
                    positionMs: playerState.position.inMilliseconds,
                    durationMs: playerState.duration.inMilliseconds,
                    onSeek: (ms) => ref
                        .read(audioPlayerProvider.notifier)
                        .seek(Duration(milliseconds: ms)),
                  )
                else
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    child: LinearProgressIndicator(
                      value: playerState.duration.inMilliseconds > 0
                          ? playerState.position.inMilliseconds /
                              playerState.duration.inMilliseconds
                          : 0,
                      backgroundColor:
                          scheme.outlineVariant.withValues(alpha: 0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.primary.withValues(alpha: 0.9),
                      ),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre tactile : pendant le glissement, le pouce suit le doigt ; les seek mettent à jour les paroles.
class _SeekableProgressStrip extends StatefulWidget {
  const _SeekableProgressStrip({
    required this.scheme,
    required this.positionMs,
    required this.durationMs,
    required this.onSeek,
  });

  final ColorScheme scheme;
  final int positionMs;
  final int durationMs;
  final void Function(int milliseconds) onSeek;

  @override
  State<_SeekableProgressStrip> createState() => _SeekableProgressStripState();
}

class _SeekableProgressStripState extends State<_SeekableProgressStrip> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.durationMs > 0 ? widget.durationMs : 1;
    final fromPlayer = (widget.positionMs / maxMs).clamp(0.0, 1.0);
    final value = (_dragging ? _dragValue : fromPlayer).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      child: ColoredBox(
        color: widget.scheme.outlineVariant.withValues(alpha: 0.12),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: widget.scheme.primary.withValues(alpha: 0.95),
            inactiveTrackColor:
                widget.scheme.outlineVariant.withValues(alpha: 0.35),
            thumbColor: widget.scheme.primary,
          ),
          child: Slider(
            value: value,
            onChangeStart: widget.durationMs > 0
                ? (_) {
                    setState(() {
                      _dragging = true;
                      _dragValue = fromPlayer;
                    });
                  }
                : null,
            onChanged: widget.durationMs > 0
                ? (v) {
                    setState(() => _dragValue = v);
                    final ms =
                        (v * widget.durationMs).round().clamp(0, widget.durationMs);
                    widget.onSeek(ms);
                  }
                : null,
            onChangeEnd: widget.durationMs > 0
                ? (_) => setState(() => _dragging = false)
                : null,
          ),
        ),
      ),
    );
  }
}
