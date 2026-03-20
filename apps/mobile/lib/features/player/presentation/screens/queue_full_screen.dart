import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/core/theme/app_theme.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

/// Page plein écran de la file d'attente, style Spotify : bloc "Lecture en cours",
/// liste "Lecture aléatoire à partir de :", prochaine piste en vert, Shuffle + Minuteur en bas.
class QueueFullScreen extends ConsumerWidget {
  const QueueFullScreen({super.key});

  static const _bgDark = Color(0xFF121212);
  static const _bgGradientTop = Color(0xFF1a1a2e);
  static const _green = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final sleepRemaining = ref.watch(sleepTimerProvider);

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: playerState.queue.isEmpty
                  ? _buildEmpty(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Lecture en cours',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _NowPlayingCard(
                          song: playerState.queue[playerState.currentIndex],
                          isPlaying: playerState.isPlaying,
                          onPlayPause: () {
                            if (playerState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).resume();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            playerState.isShuffled
                                ? 'Lecture aléatoire à partir de :'
                                : 'À suivre :',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _UpcomingList(
                            queue: playerState.queue,
                            currentIndex: playerState.currentIndex,
                            onSkipTo: (index) => ref
                                .read(audioPlayerProvider.notifier)
                                .skipToIndex(index),
                            onReorder: (oldIndex, newIndex) => ref
                                .read(audioPlayerProvider.notifier)
                                .reorderQueue(oldIndex, newIndex),
                          ),
                        ),
                      ],
                    ),
            ),
            _buildBottomBar(
                context, ref, playerState.isShuffled, sleepRemaining),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bgGradientTop.withOpacity(0.95),
            _bgGradientTop.withOpacity(0.0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: Colors.white,
              iconSize: 32,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'File d\'attente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 72,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),
          Text(
            'La file d\'attente est vide',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    bool isShuffled,
    int? sleepRemaining,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: _bgDark,
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleShuffle(),
              icon: Icon(
                isShuffled ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                color: _green,
                size: 24,
              ),
              label: Text(
                'Lecture aléatoire',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showSleepTimerSheet(context, ref),
              icon: Icon(
                Icons.timer_outlined,
                color: Colors.white70,
                size: 24,
              ),
              label: Text(
                sleepRemaining != null && sleepRemaining > 0
                    ? '${(sleepRemaining / 60).ceil()} min'
                    : 'Minuteur',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final remaining = ref.watch(sleepTimerProvider);
          final defaultMinutes =
              ref.watch(sleepTimerDefaultMinutesProvider).valueOrNull ?? 0;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Minuteur de sommeil',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (remaining != null && remaining > 0) ...[
                      Text(
                        'Arrêt dans ${(remaining / 60).ceil()} min',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(sleepTimerProvider.notifier).cancel();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Minuteur annulé'),
                                behavior: SnackBarBehavior.floating),
                          );
                        },
                        icon: const Icon(Icons.close),
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
                                    'Arrêt dans $defaultMinutes min (défaut)'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer),
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

class _NowPlayingCard extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const _NowPlayingCard({
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final path = song.albumArtPath;
    final hasArt = path != null && path.isNotEmpty && File(path).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlayPause,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasArt
                    ? Image.file(
                        File(path),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.white12,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white38,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  final List<SongModel> queue;
  final int currentIndex;
  final void Function(int index) onSkipTo;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _UpcomingList({
    required this.queue,
    required this.currentIndex,
    required this.onSkipTo,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingCount = queue.length - (currentIndex + 1);
    if (upcomingCount <= 0) {
      return const Center(
        child: Text(
          'Aucune piste suivante',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: upcomingCount,
      itemBuilder: (context, index) {
        final queueIndex = currentIndex + 1 + index;
        final song = queue[queueIndex];
        final isNext = index == 0;
        return _QueueTile(
          key: ValueKey(song.id),
          song: song,
          isNext: isNext,
          onTap: () => onSkipTo(queueIndex),
          dragHandle: ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle_rounded,
              color: Colors.white38,
              size: 24,
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        final oldFull = currentIndex + 1 + oldIndex;
        final newFull = currentIndex + 1 + newIndex;
        onReorder(oldFull, newFull);
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  final SongModel song;
  final bool isNext;
  final VoidCallback onTap;
  final Widget dragHandle;

  const _QueueTile({
    super.key,
    required this.song,
    required this.isNext,
    required this.onTap,
    required this.dragHandle,
  });

  static const _green = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final path = song.albumArtPath;
    final hasArt = path != null && path.isNotEmpty && File(path).existsSync();

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: onTap,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: hasArt
                ? Image.file(
                    File(path),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.white12,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white38,
                      size: 24,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            if (isNext) ...[
              Icon(Icons.play_arrow_rounded, color: _green, size: 20),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isNext ? _green : Colors.white70,
                  fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isNext ? _green.withOpacity(0.9) : Colors.white38,
            fontSize: 13,
          ),
        ),
        trailing: dragHandle,
      ),
    );
  }
}
