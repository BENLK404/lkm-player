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

  Color _onColorFor(Color bg) =>
      bg.computeLuminance() > 0.52 ? Colors.black : Colors.white;

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
    final scheme = Theme.of(context).colorScheme;

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

    final bgColor = dominantColor ?? Colors.black;
    final onBg = _onColorFor(bgColor);
    final onBgDim = onBg.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background (Image + gradient + blur)
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(color: bgColor),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (currentSong.albumArtPath != null)
                    Image.file(
                      File(currentSong.albumArtPath!),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bgColor.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            onBg.withValues(alpha: 0.10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: onBg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Lecture en cours',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: onBg.withValues(alpha: 0.90),
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            Text(
                              currentSong.album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: onBgDim,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            onBg.withValues(alpha: 0.10),
                          ),
                        ),
                        onPressed: () => context.push(AppRouter.queue),
                        icon: Icon(Icons.queue_music_rounded, color: onBg),
                        tooltip: 'File d\'attente',
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Cover (sans carte en dessous)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedScale(
                      scale: playerState.isPlaying ? 1.0 : 0.94,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AlbumArtImageLarge(
                          songId: currentSong.id,
                          albumArtPath: currentSong.albumArtPath,
                          heroTag: 'album-art-${currentSong.id}',
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Info + controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: onBg,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: onBgDim,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                onBg.withValues(alpha: 0.10),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(musicProvider.notifier)
                                  .toggleFavoriteStatus(currentSong);
                            },
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
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
                                key: ValueKey<bool>(isFavorite),
                                color: isFavorite
                                    ? const Color(0xFFFF3B30)
                                    : onBgDim,
                              ),
                            ),
                          ),
                          IconButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                onBg.withValues(alpha: 0.10),
                              ),
                            ),
                            icon: Icon(Icons.more_horiz_rounded, color: onBg),
                            onPressed: () =>
                                _showOptionsMenu(context, ref, currentSong),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Theme(
                        data: Theme.of(context).copyWith(
                          sliderTheme: Theme.of(context).sliderTheme.copyWith(
                                activeTrackColor:
                                    scheme.primary.withValues(alpha: 0.95),
                                inactiveTrackColor:
                                    onBg.withValues(alpha: 0.12),
                                thumbColor: scheme.primary,
                              ),
                        ),
                        child: _SeekBar(
                          position: playerState.position,
                          duration: playerState.duration,
                          formatDuration: _formatDuration,
                          onSeek: (d) =>
                              ref.read(audioPlayerProvider.notifier).seek(d),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              playerState.isShuffled
                                  ? Icons.shuffle_on_rounded
                                  : Icons.shuffle_rounded,
                              color: playerState.isShuffled ? onBg : onBgDim,
                            ),
                            onPressed: () => ref
                                .read(audioPlayerProvider.notifier)
                                .toggleShuffle(),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_previous_rounded, color: onBg),
                            iconSize: 44,
                            onPressed: () => ref
                                .read(audioPlayerProvider.notifier)
                                .previous(),
                          ),
                          IconButton(
                            icon: Icon(
                              playerState.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: onBg,
                            ),
                            iconSize: 74,
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
                            icon: Icon(Icons.skip_next_rounded, color: onBg),
                            iconSize: 44,
                            onPressed: () =>
                                ref.read(audioPlayerProvider.notifier).next(),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final repeatMode = ref.watch(
                                audioPlayerProvider
                                    .select((s) => s.repeatMode),
                              );
                              return IconButton(
                                icon: Icon(
                                  _getRepeatIcon(repeatMode),
                                  color: repeatMode != RepeatMode.off
                                      ? onBg
                                      : onBgDim,
                                ),
                                onPressed: () => ref
                                    .read(audioPlayerProvider.notifier)
                                    .toggleRepeat(),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.lyrics_outlined, color: onBg),
                            onPressed: () => context.push(AppRouter.lyrics),
                            tooltip: 'Paroles',
                          ),
                          InkWell(
                            onTap: () {
                              final current = playerState.playbackSpeed;
                              final next = current <= 1.0
                                  ? 1.5
                                  : (current < 2.0 ? 2.0 : 1.0);
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .setSpeed(next);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                '${playerState.playbackSpeed.toStringAsFixed(1)}×',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: onBgDim,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.equalizer_rounded, color: onBgDim),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const EqualizerSheet(),
                              );
                            },
                            tooltip: 'Égaliseur',
                          ),
                        ],
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
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu(
      BuildContext context, WidgetRef ref, SongModel currentSong) {
    final sleepRemaining = ref.watch(sleepTimerProvider);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight =
                  MediaQuery.sizeOf(context).height * 0.72; // compact phones
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight.isFinite
                      ? constraints.maxHeight.clamp(0, maxHeight)
                      : maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Options',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Fermer',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        currentSong.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
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
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scheme.primary, size: 24),
          ),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
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
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
