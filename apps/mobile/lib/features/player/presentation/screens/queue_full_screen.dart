import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

/// File d’attente plein écran — alignée sur le thème de l’app, listes légères
/// (pas de I/O disque synchrone par ligne, `select` pour éviter les rebuilds inutiles).
class QueueFullScreen extends ConsumerWidget {
  const QueueFullScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _QueueAppBar(),
            Expanded(
              child: queue.isEmpty
                  ? const _QueueEmptyBody()
                  : const _QueueMainBody(),
            ),
            const _QueueBottomBar(),
          ],
        ),
      ),
    );
  }
}

class _QueueAppBar extends StatelessWidget {
  const _QueueAppBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
      child: Row(
        children: [
          Material(
            color: scheme.surfaceContainerHigh,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: scheme.onSurface,
              iconSize: 28,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'File d’attente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueEmptyBody extends StatelessWidget {
  const _QueueEmptyBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 72,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 20),
          Text(
            'La file d’attente est vide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _QueueMainBody extends ConsumerWidget {
  const _QueueMainBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffled =
        ref.watch(audioPlayerProvider.select((s) => s.isShuffled));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, 'Lecture en cours'),
        const SizedBox(height: 6),
        const _CurrentTrackCard(),
        const SizedBox(height: 18),
        _sectionLabel(
          context,
          isShuffled ? 'Lecture aléatoire à partir de :' : 'À suivre',
        ),
        const SizedBox(height: 6),
        const Expanded(child: _UpcomingListBody()),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ne reconstruit que si morceau en cours, index ou lecture changent (pas la position).
class _CurrentTrackCard extends ConsumerWidget {
  const _CurrentTrackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final index = ref.watch(audioPlayerProvider.select((s) => s.currentIndex));
    final isPlaying =
        ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final notifier = ref.read(audioPlayerProvider.notifier);

    if (queue.isEmpty || index < 0 || index >= queue.length) {
      return const SizedBox.shrink();
    }
    final song = queue[index];
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (isPlaying) {
              notifier.pause();
            } else {
              notifier.resume();
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                RepaintBoundary(
                  child: _QueueAlbumArt(song: song, size: 56, radius: 12),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (isPlaying) {
                      notifier.pause();
                    } else {
                      notifier.resume();
                    }
                  },
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: scheme.primary,
                    size: 48,
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

/// Liste à venir + réordonnancement — `select` sur queue / index uniquement.
class _UpcomingListBody extends ConsumerWidget {
  const _UpcomingListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final currentIndex =
        ref.watch(audioPlayerProvider.select((s) => s.currentIndex));
    final notifier = ref.read(audioPlayerProvider.notifier);

    final upcomingCount = queue.length - (currentIndex + 1);
    if (upcomingCount <= 0) {
      return Center(
        child: Text(
          'Aucune piste suivante',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      buildDefaultDragHandles: false,
      itemCount: upcomingCount,
      itemBuilder: (context, index) {
        final queueIndex = currentIndex + 1 + index;
        final song = queue[queueIndex];
        final isNext = index == 0;
        return RepaintBoundary(
          key: ValueKey<String>('q-${song.id}-$queueIndex'),
          child: _QueueTile(
            song: song,
            isNext: isNext,
            onTap: () => notifier.skipToIndex(queueIndex),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        final oldFull = currentIndex + 1 + oldIndex;
        final newFull = currentIndex + 1 + newIndex;
        notifier.reorderQueue(oldFull, newFull);
      },
    );
  }
}

/// Pochette sans `existsSync` : decode limité, erreur → placeholder.
class _QueueAlbumArt extends StatelessWidget {
  const _QueueAlbumArt({
    required this.song,
    required this.size,
    this.radius = 8,
  });

  final SongModel song;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr).round();
    final br = BorderRadius.circular(radius);
    final path = song.albumArtPath;

    Widget placeholder() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: br,
          color: scheme.surfaceContainerHighest,
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: scheme.onSurfaceVariant,
          size: size * 0.45,
        ),
      );
    }

    if (path == null || path.isEmpty) {
      return placeholder();
    }

    if (path.startsWith('content://')) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: px,
          cacheHeight: px,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: br,
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: px,
        cacheHeight: px,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder(),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.song,
    required this.isNext,
    required this.onTap,
    required this.dragHandle,
  });

  final SongModel song;
  final bool isNext;
  final VoidCallback onTap;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final titleColor = isNext ? primary : scheme.onSurface;
    final subColor = isNext
        ? primary.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        leading: _QueueAlbumArt(song: song, size: 48, radius: 10),
        title: Row(
          children: [
            if (isNext) ...[
              Icon(Icons.play_arrow_rounded, color: primary, size: 20),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: titleColor,
                      fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subColor),
        ),
        trailing: dragHandle,
      ),
    );
  }
}

class _QueueBottomBar extends ConsumerWidget {
  const _QueueBottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffled =
        ref.watch(audioPlayerProvider.select((s) => s.isShuffled));
    final sleepRemaining = ref.watch(sleepTimerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      ref.read(audioPlayerProvider.notifier).toggleShuffle(),
                  icon: Icon(
                    isShuffled
                        ? Icons.shuffle_on_rounded
                        : Icons.shuffle_rounded,
                    size: 22,
                  ),
                  label: const Text('Aléatoire'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSleepTimerSheet(context, ref),
                  icon: const Icon(Icons.timer_outlined, size: 22),
                  label: Text(
                    sleepRemaining != null && sleepRemaining > 0
                        ? '${(sleepRemaining / 60).ceil()} min'
                        : 'Minuteur',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final remaining = ref.watch(sleepTimerProvider);
          final defaultMinutes =
              ref.watch(sleepTimerDefaultMinutesProvider).valueOrNull ?? 0;
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Minuteur de sommeil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (remaining != null && remaining > 0) ...[
                      Text(
                        'Arrêt dans ${(remaining / 60).ceil()} min',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(sleepTimerProvider.notifier).cancel();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Minuteur annulé'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Annuler le minuteur'),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [15, 30, 45, 60].map((m) {
                          return ActionChip(
                            label: Text('$m min'),
                            onPressed: () {
                              ref.read(sleepTimerProvider.notifier).start(m);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Arrêt dans $m min'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      if (defaultMinutes > 0) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(sleepTimerProvider.notifier)
                                .start(defaultMinutes);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Arrêt dans $defaultMinutes min (défaut)',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer_outlined),
                          label: Text('$defaultMinutes min (défaut)'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
