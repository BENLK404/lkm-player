import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/providers/app_providers.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/data/models/player_state.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/player/presentation/providers/now_playing_design_provider.dart';
import 'package:musio/features/player/presentation/providers/now_playing_tuning_provider.dart';
import 'package:musio/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:musio/features/player/presentation/widgets/equalizer_sheet.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:share_plus/share_plus.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(audioPlayerProvider.select((s) => s.currentSong));
    final scheme = Theme.of(context).colorScheme;
    if (song == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Aucune musique en cours',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return _NowPlayingBody(song: song);
  }
}

class _NowPlayingBody extends ConsumerWidget {
  const _NowPlayingBody({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(nowPlayingDesignProvider).valueOrNull ??
        NowPlayingDesign.classic;
    return switch (design) {
      NowPlayingDesign.classic => _ClassicNowPlayingLayout(song: song),
      NowPlayingDesign.immersive => _ImmersiveNowPlayingLayout(song: song),
      NowPlayingDesign.minimal => _MinimalNowPlayingLayout(song: song),
      NowPlayingDesign.vinyl => _VinylNowPlayingLayout(song: song),
    };
  }
}

// ─── Mises en page (design au choix) ───────────────────────────────────────

class _ClassicNowPlayingLayout extends StatelessWidget {
  const _ClassicNowPlayingLayout({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      child: _AlbumCoverCard(song: song, design: NowPlayingDesign.classic),
                    ),
                    const SizedBox(height: 24),
                    _TitleRow(song: song),
                    const SizedBox(height: 20),
                    const _WavySeekSection(),
                    const SizedBox(height: 28),
                    const _MainTransportRow(),
                    const SizedBox(height: 32),
                    _BottomActionsPill(song: song),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImmersiveNowPlayingLayout extends StatelessWidget {
  const _ImmersiveNowPlayingLayout({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _BlurredArtBackdrop(song: song),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(inverseChrome: true),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          child: _AlbumCoverCard(
                            song: song,
                            design: NowPlayingDesign.immersive,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _TitleRow(song: song, lightOnDark: true),
                        const SizedBox(height: 24),
                        const _LinearSeekSection(lightOnDark: true),
                        const SizedBox(height: 28),
                        const _MainTransportRow(lightOnDark: true),
                        const SizedBox(height: 28),
                        _BottomActionsPill(song: song, lightOnDark: true),
                        const SizedBox(height: 20),
                      ],
                    ),
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

class _MinimalNowPlayingLayout extends StatelessWidget {
  const _MinimalNowPlayingLayout({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    RepaintBoundary(
                      child: _AlbumCoverCard(
                        song: song,
                        design: NowPlayingDesign.minimal,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _TitleRow(song: song, centered: true),
                    const SizedBox(height: 32),
                    const _LinearSeekSection(),
                    const SizedBox(height: 36),
                    const _MainTransportRow(),
                    const SizedBox(height: 40),
                    _BottomActionsPill(song: song),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinylNowPlayingLayout extends StatelessWidget {
  const _VinylNowPlayingLayout({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      child: _AlbumCoverCard(
                        song: song,
                        design: NowPlayingDesign.vinyl,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _TitleRow(song: song),
                    const SizedBox(height: 22),
                    const _LinearSeekSection(),
                    const SizedBox(height: 26),
                    const _MainTransportRow(),
                    const SizedBox(height: 30),
                    _BottomActionsPill(song: song),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({this.inverseChrome = false});

  final bool inverseChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final onIcon = inverseChrome ? Colors.white : scheme.onSurface;
    final titleColor = inverseChrome ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          _RoundChrome(
            inverse: inverseChrome,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: onIcon,
            ),
          ),
          Expanded(
            child: Text(
              'Lecture en cours',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
            ),
          ),
          _RoundChrome(
            inverse: inverseChrome,
            child: IconButton(
              onPressed: () => _showVolumeSheet(context, ref),
              icon: const Icon(Icons.volume_up_rounded),
              color: onIcon,
              tooltip: 'Volume',
            ),
          ),
          const SizedBox(width: 4),
          _RoundChrome(
            inverse: inverseChrome,
            child: IconButton(
              onPressed: () => context.push(AppRouter.queue),
              icon: const Icon(Icons.queue_music_rounded),
              color: onIcon,
              tooltip: 'File d\'attente',
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundChrome extends StatelessWidget {
  const _RoundChrome({required this.child, this.inverse = false});

  final Widget child;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = inverse
        ? Colors.white.withValues(alpha: 0.14)
        : scheme.surfaceContainerHigh;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 44,
        height: 44,
        child: child,
      ),
    );
  }
}

Widget _nowPlayingCoverImage(
  BuildContext context,
  SongModel song,
  double width,
  int cachePx,
  ColorScheme scheme,
) {
  final path = song.albumArtPath;
  if (path != null && path.startsWith('content://')) {
    return AlbumArtImage(
      songId: song.id,
      albumArtPath: path,
      size: width,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
    );
  }
  if (path != null && File(path).existsSync()) {
    return Image.file(
      File(path),
      width: width,
      height: width,
      fit: BoxFit.cover,
      cacheWidth: cachePx,
      cacheHeight: cachePx,
      errorBuilder: (_, __, ___) => _nowPlayingCoverPlaceholder(scheme),
    );
  }
  return _nowPlayingCoverPlaceholder(scheme);
}

Widget _nowPlayingCoverPlaceholder(ColorScheme scheme) {
  return ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 80,
        color: scheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Fond pochette floutée (mode immersion) — paramètres depuis les réglages.
class _BlurredArtBackdrop extends ConsumerWidget {
  const _BlurredArtBackdrop({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final blur = tuning.immersiveBlurSigma.clamp(20.0, 80.0);
    final darken = tuning.immersiveOverlayDarken.clamp(0.05, 0.95);

    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = math.max(size.width, size.height) * 1.35;
    final cachePx = (side * dpr).round();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: side,
                height: side,
                child: _nowPlayingCoverImage(
                  context,
                  song,
                  side,
                  cachePx,
                  scheme,
                ),
              ),
            ),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: darken)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pochette — forme selon [design] et réglages persistés.
class _AlbumCoverCard extends ConsumerWidget {
  const _AlbumCoverCard({
    required this.song,
    this.design = NowPlayingDesign.classic,
  });

  final SongModel song;
  final NowPlayingDesign design;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final screenW = MediaQuery.sizeOf(context).width;
    final scheme = Theme.of(context).colorScheme;

    final double side = switch (design) {
      NowPlayingDesign.classic => screenW - 40,
      NowPlayingDesign.immersive => screenW - 48,
      NowPlayingDesign.minimal =>
        (screenW * tuning.minimalCoverFraction).clamp(200.0, 340.0),
      NowPlayingDesign.vinyl =>
        (screenW - 56).clamp(200.0, tuning.vinylCoverMaxSide),
    };

    final discPad = tuning.vinylDiscPadding.clamp(4.0, 24.0);
    final ring = discPad * 2 + 8;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (side * dpr).round();

    final cover = _nowPlayingCoverImage(context, song, side, cachePx, scheme);

    switch (design) {
      case NowPlayingDesign.vinyl:
        return Center(
          child: Container(
            width: side + ring,
            height: side + ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: EdgeInsets.all(discPad),
            child: ClipOval(child: cover),
          ),
        );
      case NowPlayingDesign.minimal:
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: side,
              height: side,
              child: cover,
            ),
          ),
        );
      case NowPlayingDesign.immersive:
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: cover,
            ),
          ),
        );
      case NowPlayingDesign.classic:
        return AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: cover,
          ),
        );
    }
  }
}

class _TitleRow extends ConsumerWidget {
  const _TitleRow({
    required this.song,
    this.lightOnDark = false,
    this.centered = false,
  });

  final SongModel song;
  final bool lightOnDark;
  final bool centered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = lightOnDark ? Colors.white : scheme.onSurface;
    final artistColor =
        lightOnDark ? Colors.white.withValues(alpha: 0.72) : scheme.onSurfaceVariant;
    final chipBg = lightOnDark
        ? Colors.white.withValues(alpha: 0.14)
        : scheme.surfaceContainerHigh;
    final lyricsIcon = lightOnDark ? Colors.white : scheme.primary;

    final textBlock = Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: artistColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );

    if (centered) {
      return Column(
        children: [
          textBlock,
          const SizedBox(height: 16),
          Material(
            color: chipBg,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(AppRouter.lyrics),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.lyrics_outlined, color: lyricsIcon),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: textBlock),
        const SizedBox(width: 12),
        Material(
          color: chipBg,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRouter.lyrics),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.lyrics_outlined, color: lyricsIcon),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rebuild uniquement position / durée (pas tout l’écran).
class _WavySeekSection extends ConsumerWidget {
  const _WavySeekSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final tuning =
        ref.watch(nowPlayingTuningProvider).valueOrNull ?? const NowPlayingTuning();
    final amp = tuning.classicWaveAmplitude.clamp(2.0, 14.0);

    return _WavySeekBar(
      position: position,
      duration: duration,
      onSeek: (d) => ref.read(audioPlayerProvider.notifier).seek(d),
      waveAmplitude: amp,
    );
  }
}

class _WavySeekBar extends StatefulWidget {
  const _WavySeekBar({
    required this.position,
    required this.duration,
    required this.onSeek,
    this.waveAmplitude = 5,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final double waveAmplitude;

  @override
  State<_WavySeekBar> createState() => _WavySeekBarState();
}

class _WavySeekBarState extends State<_WavySeekBar> {
  bool _dragging = false;
  double _dragProgress = 0;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMs = widget.duration.inMilliseconds;
    final max = maxMs > 0 ? maxMs.toDouble() : 1.0;
    final pMs = widget.position.inMilliseconds.toDouble().clamp(0.0, max);
    final progress = _dragging ? _dragProgress : (pMs / max).clamp(0.0, 1.0);
    final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                final x = d.localPosition.dx.clamp(0.0, w);
                setState(() {
                  _dragging = true;
                  _dragProgress = x / w;
                });
              },
              onHorizontalDragUpdate: (d) {
                final x = d.localPosition.dx.clamp(0.0, w);
                setState(() => _dragProgress = x / w);
              },
              onHorizontalDragEnd: (_) {
                final ms = (_dragProgress * max).round();
                widget.onSeek(Duration(milliseconds: ms));
                Future.microtask(() => setState(() => _dragging = false));
              },
              onTapDown: (d) {
                final x = d.localPosition.dx.clamp(0.0, w);
                final ms = ((x / w) * max).round();
                widget.onSeek(Duration(milliseconds: ms));
              },
              child: SizedBox(
                height: 40,
                width: w,
                child: CustomPaint(
                  painter: _WavyProgressPainter(
                    progress: progress,
                    activeColor: scheme.primary,
                    inactiveColor: scheme.outlineVariant,
                    thumbRingColor: scheme.surface,
                    amplitude: widget.waveAmplitude,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(_dragging
                    ? Duration(milliseconds: (_dragProgress * max).round())
                    : widget.position),
                style: timeStyle,
              ),
              Text(
                _fmt(widget.duration),
                style: timeStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  _WavyProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbRingColor,
    required this.amplitude,
  });

  /// Période fixe en pixels : les ondes ne s’étirent pas quand la lecture avance.
  static const double _wavelengthPx = 26;

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbRingColor;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final activeW = size.width * progress;

    // Partie non lue : ligne fine droite
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(activeW, midY),
      Offset(size.width, midY),
      inactivePaint,
    );

    if (activeW <= 0) return;

    final path = Path();
    var first = true;
    for (double x = 0; x <= activeW; x += 1.5) {
      final y =
          midY + amplitude * math.sin(2 * math.pi * x / _wavelengthPx);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final wavePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, wavePaint);

    // Pastille au point courant
    final thumbX = activeW.clamp(6.0, size.width - 6);
    final thumbY =
        midY + amplitude * math.sin(2 * math.pi * thumbX / _wavelengthPx);
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      7,
      Paint()..color = activeColor,
    );
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      7,
      Paint()
        ..color = thumbRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.thumbRingColor != thumbRingColor;
  }
}

/// Barre de position classique (sliders) — vinyle, minimal, immersion.
class _LinearSeekSection extends ConsumerWidget {
  const _LinearSeekSection({this.lightOnDark = false});

  final bool lightOnDark;

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration =
        ref.watch(audioPlayerProvider.select((s) => s.duration));
    final scheme = Theme.of(context).colorScheme;
    final maxMs = duration.inMilliseconds;
    final progress = maxMs > 0
        ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
        : 0.0;

    final inactive = lightOnDark
        ? Colors.white.withValues(alpha: 0.28)
        : scheme.outlineVariant.withValues(alpha: 0.4);
    final active = lightOnDark ? Colors.white : scheme.primary;
    final textC = lightOnDark
        ? Colors.white.withValues(alpha: 0.78)
        : scheme.onSurfaceVariant;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: active,
            inactiveTrackColor: inactive,
            thumbColor: active,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: maxMs > 0
                ? (v) {
                    ref.read(audioPlayerProvider.notifier).seek(
                          Duration(milliseconds: (v * maxMs).round()),
                        );
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(position),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textC,
                    ),
              ),
              Text(
                _fmt(duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textC,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MainTransportRow extends ConsumerWidget {
  const _MainTransportRow({this.lightOnDark = false});

  final bool lightOnDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isPlaying =
        ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final notifier = ref.read(audioPlayerProvider.notifier);

    final playBg = lightOnDark ? Colors.white : scheme.primary;
    final playIcon = lightOnDark ? Colors.black : scheme.onPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SideTransportButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () => notifier.previous(),
          lightOnDark: lightOnDark,
        ),
        const SizedBox(width: 20),
        Material(
          color: playBg,
          borderRadius: BorderRadius.circular(22),
          elevation: 0,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isPlaying) {
                notifier.pause();
              } else {
                notifier.resume();
              }
            },
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: playIcon,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        _SideTransportButton(
          icon: Icons.skip_next_rounded,
          onPressed: () => notifier.next(),
          lightOnDark: lightOnDark,
        ),
      ],
    );
  }
}

class _SideTransportButton extends StatelessWidget {
  const _SideTransportButton({
    required this.icon,
    required this.onPressed,
    this.lightOnDark = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool lightOnDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = lightOnDark
        ? Colors.white.withValues(alpha: 0.14)
        : scheme.surfaceContainerHigh;
    final ic = lightOnDark ? Colors.white : scheme.primary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: ic, size: 30),
        ),
      ),
    );
  }
}

class _BottomActionsPill extends ConsumerWidget {
  const _BottomActionsPill({required this.song, this.lightOnDark = false});

  final SongModel song;
  final bool lightOnDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffled =
        ref.watch(audioPlayerProvider.select((s) => s.isShuffled));
    final repeatMode =
        ref.watch(audioPlayerProvider.select((s) => s.repeatMode));
    final isFavorite = ref.watch(
      musicProvider.select(
        (async) => async.maybeWhen(
          data: (state) => state.songs
              .firstWhere(
                (s) => s.id == song.id,
                orElse: () => song,
              )
              .isFavorite,
          orElse: () => song.isFavorite,
        ),
      ),
    );

    final notifier = ref.read(audioPlayerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final muted =
        lightOnDark ? Colors.white.withValues(alpha: 0.55) : scheme.onSurfaceVariant;
    final active = lightOnDark ? Colors.white : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: lightOnDark
            ? Colors.white.withValues(alpha: 0.1)
            : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => notifier.toggleShuffle(),
            icon: Icon(
              isShuffled ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
              color: isShuffled ? active : muted,
            ),
          ),
          IconButton(
            onPressed: () => notifier.toggleRepeat(),
            icon: Icon(
              _repeatIcon(repeatMode),
              color: repeatMode != RepeatMode.off ? active : muted,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(musicProvider.notifier).toggleFavoriteStatus(song);
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? active : muted,
            ),
          ),
          IconButton(
            onPressed: () => _showOptionsMenu(context, ref, song),
            icon: Icon(Icons.more_horiz_rounded, color: muted),
            tooltip: 'Plus',
          ),
        ],
      ),
    );
  }

  static IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_on_rounded;
      case RepeatMode.all:
        return Icons.repeat_on_rounded;
    }
  }
}

// ─── Volume (just_audio) ───────────────────────────────────────────────────

void _showVolumeSheet(BuildContext context, WidgetRef ref) {
  final player = ref.read(audioHandlerProvider).player;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: StreamBuilder<double>(
            stream: player.volumeStream,
            initialData: player.volume,
            builder: (context, snap) {
              final v = snap.data ?? 1.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  Text(
                    'Volume de lecture',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.volume_mute_rounded,
                        size: 26,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                          ),
                          child: Slider(
                            value: v.clamp(0.0, 1.0),
                            onChanged: (nv) => player.setVolume(nv),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.volume_up_rounded,
                        size: 26,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    },
  );
}

// ─── Menu options (playlists, partage, minuteur, égaliseur…) ────────────────

void _showOptionsMenu(
  BuildContext context,
  WidgetRef ref,
  SongModel currentSong,
) {
  final sleepRemaining = ref.read(sleepTimerProvider);
  final scheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
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
                    padding: const EdgeInsets.fromLTRB(22, 0, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Options',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 24,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                          tooltip: 'Fermer',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      currentSong.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 20, top: 8),
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
                              'J\'écoute ${currentSong.title} de ${currentSong.artist} sur Musio !',
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
                        _OptionTile(
                          icon: Icons.speed_rounded,
                          label: 'Vitesse de lecture',
                          onTap: () {
                            Navigator.pop(context);
                            _showSpeedSheet(context, ref);
                          },
                        ),
                        _OptionTile(
                          icon: Icons.equalizer_rounded,
                          label: 'Égaliseur',
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet<void>(
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
            );
          },
        ),
      ),
    ),
  );
}

void _showSpeedSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final speed = ref.watch(audioPlayerProvider.select((s) => s.playbackSpeed));
        final scheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 8),
                    child: Text(
                      'Vitesse',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: scheme.onSurface,
                          ),
                    ),
                  ),
                  ...[0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                    final sel = (speed - s).abs() < 0.01;
                    return _ThinSheetRow(
                      label: '$s×',
                      selected: sel,
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).setSpeed(s);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final remaining = ref.watch(sleepTimerProvider);
        final defaultMinutes =
            ref.watch(sleepTimerDefaultMinutesProvider).valueOrNull ?? 0;

        final scheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 8),
                    child: Text(
                      'Minuteur de sommeil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: scheme.onSurface,
                          ),
                    ),
                  ),
                  if (remaining != null && remaining > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Arrêt dans ${(remaining / 60).ceil()} min',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          side: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
                        child: const Text('Annuler le minuteur'),
                      ),
                    ),
                  ] else ...[
                    ...[15, 30, 45, 60].map((m) {
                      return _ThinSheetRow(
                        label: '$m min',
                        selected: false,
                        onTap: () {
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
                    }),
                    if (defaultMinutes > 0)
                      _ThinSheetRow(
                        label: '$defaultMinutes min (défaut)',
                        selected: false,
                        onTap: () {
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
                      ),
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
  BuildContext context,
  WidgetRef ref,
  SongModel song,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final playlists = ref.watch(musicProvider).asData?.value.playlists ?? [];
      final scheme = Theme.of(context).colorScheme;
      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajouter à une playlist',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Aucune playlist trouvée.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.queue_music_rounded,
                          size: 28,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        title: Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        subtitle: Text(
                          '${playlist.songIds.length} titres',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                        ),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 26, color: muted),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne fine pour feuilles vitesse / minuteur (style neutre).
class _ThinSheetRow extends StatelessWidget {
  const _ThinSheetRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.88),
                      ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 24,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
            ],
          ),
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
        margin: const EdgeInsets.only(top: 10, bottom: 14),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
