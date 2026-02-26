import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/data/models/player_state.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/player/presentation/widgets/audio_visualizer.dart';
import 'package:musio/features/player/presentation/widgets/equalizer_sheet.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:share_plus/share_plus.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;

    if (currentSong == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Aucune musique en cours'),
        ),
      );
    }

    final musicState = ref.watch(musicProvider);
    final isFavorite = musicState.maybeWhen(
      data: (state) => state.songs
          .firstWhere(
            (s) => s.id == currentSong.id,
            orElse: () => currentSong,
          )
          .isFavorite,
      orElse: () => currentSong.isFavorite,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fond flouté
          if (currentSong.albumArtPath != null)
            Positioned.fill(
              child: Image.file(
                File(currentSong.albumArtPath!),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(color: Theme.of(context).colorScheme.surface),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color:
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
              ),
            ),
          ),

          // Contenu
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            'EN LECTURE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.album,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () =>
                            _showOptionsMenu(context, ref, currentSong),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Album art (plus grand et avec ombre)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AlbumArtImageLarge(
                          songId: currentSong.id,
                          albumArtPath: currentSong.albumArtPath,
                          heroTag: 'album-art-${currentSong.id}',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                AudioVisualizer(
                  isPlaying: playerState.isPlaying,
                  barCount: 28,
                  barWidth: 3,
                  minHeight: 6,
                  maxHeight: 28,
                ),
                const SizedBox(height: 16),

                // Song info & Favorite
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentSong.artist,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        iconSize: 32,
                        color: isFavorite
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        onPressed: () {
                          ref
                              .read(musicProvider.notifier)
                              .toggleFavoriteStatus(currentSong);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress bar (seek uniquement à la fin du glissement pour éviter la lenteur)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SeekBar(
                    position: playerState.position,
                    duration: playerState.duration,
                    formatDuration: _formatDuration,
                    onSeek: (d) =>
                        ref.read(audioPlayerProvider.notifier).seek(d),
                  ),
                ),

                const SizedBox(height: 16),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerState.isShuffled
                              ? Icons.shuffle_on_outlined
                              : Icons.shuffle,
                          color: playerState.isShuffled
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        iconSize: 28,
                        onPressed: () {
                          ref
                              .read(audioPlayerProvider.notifier)
                              .toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 48,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).previous();
                        },
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 40,
                          onPressed: () {
                            if (playerState.isPlaying) {
                              ref.read(audioPlayerProvider.notifier).pause();
                            } else {
                              ref.read(audioPlayerProvider.notifier).resume();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 48,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).next();
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final repeatMode = ref.watch(
                              audioPlayerProvider.select((s) => s.repeatMode));
                          return IconButton(
                            icon: Icon(
                              _getRepeatIcon(repeatMode),
                              color: repeatMode != RepeatMode.off
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            iconSize: 28,
                            onPressed: () {
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .toggleRepeat();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom actions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          final current = playerState.playbackSpeed;
                          final next = current <= 1.0
                              ? 1.5
                              : (current < 2.0 ? 2.0 : 1.0);
                          ref.read(audioPlayerProvider.notifier).setSpeed(next);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.speed,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 6),
                              Text(
                                _speedLabel(playerState.playbackSpeed),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lyrics_outlined),
                        onPressed: () {
                          context.push(AppRouter.lyrics);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music),
                        onPressed: () {
                          context.push(AppRouter.queue);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.equalizer),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const EqualizerSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _speedLabel(double speed) {
    if (speed <= 1.0) return '1x';
    if (speed < 2.0) return '1.5x';
    return '2x';
  }

  IconData _getRepeatIcon(RepeatMode repeatMode) {
    switch (repeatMode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_on_rounded;
      case RepeatMode.all:
        return Icons.repeat_on_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu(
      BuildContext context, WidgetRef ref, SongModel currentSong) {
    final sleepRemaining = ref.watch(sleepTimerProvider);
    const _bgDark = Color(0xFF121212);
    const _bgGradientTop = Color(0xFF1a1a2e);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                          'Options',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  currentSong.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.playlist_add_rounded,
                label: 'Ajouter à la playlist',
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistSheet(context, ref, currentSong);
                },
              ),
              if (currentSong.albumId != null)
                _OptionTile(
                  icon: Icons.album_rounded,
                  label: 'Aller à l\'album',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/album/${currentSong.albumId!}');
                  },
                ),
              if (currentSong.artistId != null)
                _OptionTile(
                  icon: Icons.person_rounded,
                  label: 'Aller à l\'artiste',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/artist/${currentSong.artistId!}');
                  },
                ),
              _OptionTile(
                icon: Icons.share_rounded,
                label: 'Partager',
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'J\'écoute ${currentSong.title} de ${currentSong.artist} sur LKM Player !',
                  );
                },
              ),
              _OptionTile(
                icon: Icons.timer_outlined,
                label: 'Minuteur de sommeil',
                subtitle: sleepRemaining != null && sleepRemaining > 0
                    ? 'Arrêt dans ${(sleepRemaining / 60).ceil()} min'
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerSheet(context, ref);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
                    const _SheetHandle(),
                    const SizedBox(height: 8),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
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

  void _showAddToPlaylistSheet(
      BuildContext context, WidgetRef ref, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final playlists =
            ref.watch(musicProvider).asData?.value.playlists ?? [];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Ajouter à une playlist',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Aucune playlist trouvée.'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.music_note,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} titres'),
                          onTap: () {
                            ref
                                .read(musicProvider.notifier)
                                .addSongToPlaylist(song.id, playlist.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ajouté à "${playlist.name}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        onTap: onTap,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: primary.withOpacity(0.9),
                  fontSize: 13,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Barre de progression : seek uniquement à la fin du glissement (onChangeEnd)
/// pour éviter les appels répétés pendant le drag et la lenteur.
class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.position,
    required this.duration,
    required this.formatDuration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.duration.inMilliseconds;
    final max = maxMs > 0 ? maxMs.toDouble() : 1.0;
    final positionMs =
        widget.position.inMilliseconds.toDouble().clamp(0.0, max);
    final value = _isDragging ? _dragValue : positionMs;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            thumbColor: Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: value,
            max: max,
            onChanged: (v) {
              setState(() {
                _isDragging = true;
                _dragValue = v;
              });
            },
            onChangeEnd: (v) {
              final position = Duration(milliseconds: v.toInt());
              widget.onSeek(position);
              // Laisser le parent se mettre à jour avant de repasser à widget.position
              Future.microtask(() => setState(() => _isDragging = false));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isDragging
                    ? widget.formatDuration(
                        Duration(milliseconds: _dragValue.toInt()))
                    : widget.formatDuration(widget.position),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                widget.formatDuration(widget.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
