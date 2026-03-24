import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart' as lyric_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/lyrics_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/mini_player.dart';

/// Paroles plein écran — aligné sur le thème de l’app, sans extraction de palette
/// (évite decode lourd). La zone de lecture ne reconstruit que sur la position audio.
class LyricsFullScreen extends ConsumerWidget {
  const LyricsFullScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final currentSong =
        ref.watch(audioPlayerProvider.select((s) => s.currentSong));

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LyricsAppBar(),
              Expanded(
                child: Center(
                  child: Text(
                    'Aucune piste en lecture',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _LyricsBackdrop(song: currentSong),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _LyricsAppBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: const MiniPlayer(seekableProgress: true),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final lyricsAsync =
                          ref.watch(lyricsProvider(currentSong.id));
                      return lyricsAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            color: scheme.primary,
                          ),
                        ),
                        error: (_, __) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: scheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Impossible de charger les paroles',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        data: (lyrics) => _LyricsReaderPane(
                          lyrics: lyrics,
                          song: currentSong,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsAppBar extends StatelessWidget {
  const _LyricsAppBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
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
              'Paroles',
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

/// Fond : dégradé thème + pochette floutée si dispo (sans `existsSync` ni palette).
class _LyricsBackdrop extends StatelessWidget {
  const _LyricsBackdrop({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = song.albumArtPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.55),
                scheme.surface,
                scheme.surfaceContainerLow,
              ],
            ),
          ),
        ),
        if (path != null && path.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, c) {
                  final dpr = MediaQuery.devicePixelRatioOf(context);
                  final w = (c.maxWidth * dpr).round().clamp(400, 900);
                  Widget art;
                  if (path.startsWith('content://')) {
                    art = Image.network(
                      path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: w,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    );
                  } else {
                    art = Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: w,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      art,
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
                        child: ColoredBox(
                          color: scheme.surface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Ne reconstruit que lorsque la position de lecture change (pas tout l’écran).
class _LyricsReaderPane extends ConsumerWidget {
  const _LyricsReaderPane({
    required this.lyrics,
    required this.song,
  });

  final String? lyrics;
  final SongModel song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final positionMs = ref.watch(
      audioPlayerProvider.select((s) => s.position.inMilliseconds),
    );

    if (lyrics == null || lyrics!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 72,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucune parole disponible',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '${song.title} · ${song.artist}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final lyricModel = lyric_ui.LyricsModelBuilder.create()
        .bindLyricToMain(lyrics!)
        .getModel();

    final active = scheme.primary;
    final inactive = scheme.onSurfaceVariant;
    final onCard = scheme.onSurface;

    return lyric_ui.LyricsReader(
      model: lyricModel,
      position: positionMs,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      emptyBuilder: () => const SizedBox.shrink(),
      selectLineBuilder: (progress, confirm) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                ref.read(audioPlayerProvider.notifier).seek(
                      Duration(milliseconds: progress),
                    );
                confirm();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: scheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aller à ce moment',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: onCard.withValues(alpha: 0.65),
                                ),
                          ),
                          Text(
                            _formatDuration(Duration(milliseconds: progress)),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: onCard,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Lire',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      lyricUi: _ThemedLyricUi(active, inactive),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ThemedLyricUi extends lyric_ui.UINetease {
  _ThemedLyricUi(this.activeColor, this.inactiveColor);

  final Color activeColor;
  final Color inactiveColor;

  @override
  TextStyle getPlayingMainTextStyle() {
    return TextStyle(
      color: activeColor,
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.25,
    );
  }

  @override
  TextStyle getPlayingExtTextStyle() {
    return TextStyle(
      color: activeColor.withValues(alpha: 0.82),
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
  }

  @override
  TextStyle getOtherMainTextStyle() {
    return TextStyle(
      color: inactiveColor,
      fontSize: 19,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );
  }

  @override
  TextStyle getOtherExtTextStyle() {
    return TextStyle(
      color: inactiveColor.withValues(alpha: 0.9),
      fontSize: 17,
      height: 1.35,
    );
  }
}
