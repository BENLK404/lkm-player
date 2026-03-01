import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/data/models/player_state.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/player/presentation/widgets/equalizer_sheet.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:share_plus/share_plus.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Color? dominantColor;
  String? lastSongId;

  Future<void> _extractDominantColor(String albumArtPath) async {
    try {
      final imageProvider = FileImage(File(albumArtPath));
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(() {
          dominantColor = palette.dominantColor?.color ??
              palette.vibrantColor?.color ??
              palette.mutedColor?.color ??
              Colors.black;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;

    if (currentSong != null && currentSong.id != lastSongId) {
      lastSongId = currentSong.id;
      if (currentSong.albumArtPath != null) {
        _extractDominantColor(currentSong.albumArtPath!);
      } else {
        dominantColor = Colors.black;
      }
    }

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

    final isLight =
        dominantColor != null && dominantColor!.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black : Colors.white;
    final iconColor = isLight ? Colors.black : Colors.white;
    final iconColorDim = isLight ? Colors.black54 : Colors.white54;
    final bgColor = dominantColor ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Image (Full Screen)
          if (currentSong.albumArtPath != null)
            Positioned.fill(
              child: Image.file(
                File(currentSong.albumArtPath!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

          // Full Blur with Dominant Color Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: bgColor.withOpacity(0.6),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          height: 10,
                          width: 60,
                        ),
                      ),
                      // Column(
                      //   children: [
                      //     Text(
                      //       currentSong.album,
                      //       style: const TextStyle(
                      //         color: Colors.white70,
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.w600,
                      //         letterSpacing: 1.2,
                      //       ),
                      //       overflow: TextOverflow.ellipsis,
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Album Art (Prominent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedScale(
                      scale: playerState.isPlaying ? 1.0 : 0.85,
                      duration: Duration(
                          milliseconds: playerState.isPlaying ? 1500 : 900),
                      curve: playerState.isPlaying
                          ? Curves.elasticOut
                          : Curves.easeInOutCirc,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AlbumArtImageLarge(
                            songId: currentSong.id,
                            albumArtPath: currentSong.albumArtPath,
                            heroTag: 'album-art-${currentSong.id}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Song Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentSong.artist,
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(musicProvider.notifier)
                              .toggleFavoriteStatus(currentSong);
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                              child: child,
                            );
                          },
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            key: ValueKey<bool>(isFavorite), // IMPORTANT
                            color: isFavorite ? Colors.red : iconColorDim,
                          ),
                        ),
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              textColor.withValues(alpha: 0.1)),
                        ),
                        icon: Icon(Icons.more_horiz_rounded, color: iconColor),
                        onPressed: () =>
                            _showOptionsMenu(context, ref, currentSong),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SeekBar(
                    position: playerState.position,
                    duration: playerState.duration,
                    formatDuration: _formatDuration,
                    onSeek: (d) =>
                        ref.read(audioPlayerProvider.notifier).seek(d),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerState.isShuffled
                              ? Icons.shuffle_on_rounded
                              : Icons.shuffle_rounded,
                          color:
                              playerState.isShuffled ? iconColor : iconColorDim,
                        ),
                        iconSize: 24,
                        onPressed: () {
                          ref
                              .read(audioPlayerProvider.notifier)
                              .toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.skip_previous_rounded, color: iconColor),
                        iconSize: 48,
                        onPressed: () {
                          ref.read(audioPlayerProvider.notifier).previous();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: iconColor,
                        ),
                        iconSize: 72,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (playerState.isPlaying) {
                            ref.read(audioPlayerProvider.notifier).pause();
                          } else {
                            ref.read(audioPlayerProvider.notifier).resume();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded, color: iconColor),
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
                                  ? iconColor
                                  : iconColorDim,
                            ),
                            iconSize: 24,
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

                const SizedBox(height: 24),

                // Bottom Actions (Volume, Lyrics, Quote, More)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    spacing: 30,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.lyrics_outlined, color: iconColor),
                        onPressed: () {
                          context.push(AppRouter.lyrics);
                        },
                      ),
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
                          child: Icon(Icons.speed_rounded, color: iconColorDim),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.equalizer_rounded, color: iconColorDim),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const EqualizerSheet(),
                          );
                        },
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.menu_rounded,
                      //       color: Colors.white54),
                      //   onPressed: () {
                      //     context.push(AppRouter.queue);
                      //   },
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
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
                      _bgGradientTop.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
