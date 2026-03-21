import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart' as lyric_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/lyrics_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:palette_generator/palette_generator.dart';

/// Page plein écran des paroles, style Spotify : fond sombre, paroles centrées
/// qui défilent avec la lecture, ligne actuelle mise en avant.
class LyricsFullScreen extends ConsumerStatefulWidget {
  const LyricsFullScreen({super.key});

  @override
  ConsumerState<LyricsFullScreen> createState() => _LyricsFullScreenState();
}

class _LyricsFullScreenState extends ConsumerState<LyricsFullScreen> {
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
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, Colors.white, Colors.white),
              const Expanded(
                child: Center(
                  child: Text('Aucune piste en lecture'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lyricsAsync = ref.watch(lyricsProvider(currentSong.id));

    final isLight =
        dominantColor != null && dominantColor!.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black : Colors.white;
    final iconColor = isLight ? Colors.black : Colors.white;
    final iconColorDim = isLight ? Colors.black54 : Colors.white54;
    final bgColor = dominantColor ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(context, currentSong.albumArtPath, bgColor),
          // Contenu
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, iconColor, textColor),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: MiniPlayer(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: lyricsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: iconColorDim,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: iconColorDim,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger les paroles',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    data: (lyrics) => _buildLyricsContent(
                      context,
                      ref,
                      lyrics,
                      currentSong,
                      playerState.position.inMilliseconds,
                      textColor,
                      iconColor,
                      iconColorDim,
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

  Widget _buildBackground(
      BuildContext context, String? albumArtPath, Color bgColor) {
    return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e).withOpacity(0.95),
              const Color(0xFF121212),
              const Color(0xFF0f0f0f),
            ],
          ),
        ),
        child: () {
          final path = albumArtPath;
          if (path == null || path.isEmpty || !File(path).existsSync()) {
            return const SizedBox.expand();
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // Gradient Blur Overlay (Full Background)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    color: bgColor.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          );
        }());
  }

  Widget _buildAppBar(BuildContext context, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            color: iconColor,
            iconSize: 32,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Paroles',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(
    BuildContext context,
    WidgetRef ref,
    String? lyrics,
    SongModel currentSong,
    int positionMs,
    Color textColor,
    Color iconColor,
    Color iconColorDim,
  ) {
    if (lyrics == null || lyrics.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 72,
              color: iconColorDim.withOpacity(0.24),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune parole disponible',
              style: TextStyle(
                color: textColor.withOpacity(0.38),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${currentSong.title} · ${currentSong.artist}',
              style: TextStyle(
                color: textColor.withOpacity(0.24),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final lyricModel =
        lyric_ui.LyricsModelBuilder.create().bindLyricToMain(lyrics).getModel();

    return lyric_ui.LyricsReader(
      model: lyricModel,
      position: positionMs,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      emptyBuilder: () => const SizedBox.shrink(),
      selectLineBuilder: (progress, confirm) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Material(
            color: textColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: iconColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aller à ce moment',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(Duration(milliseconds: progress)),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Lire',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      lyricUi: _CustomLyricUI(
        textColor,
        textColor.withOpacity(0.5),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _CustomLyricUI extends lyric_ui.UINetease {
  final Color activeColor;
  final Color inactiveColor;

  _CustomLyricUI(this.activeColor, this.inactiveColor);

  @override
  TextStyle getPlayingMainTextStyle() {
    return TextStyle(
      color: activeColor,
      fontSize: 26,
      fontWeight: FontWeight.bold,
    );
  }

  @override
  TextStyle getPlayingExtTextStyle() {
    return TextStyle(
      color: activeColor.withOpacity(0.7),
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
  }

  @override
  TextStyle getOtherMainTextStyle() {
    return TextStyle(
      color: inactiveColor,
      fontSize: 20,
    );
  }

  @override
  TextStyle getOtherExtTextStyle() {
    return TextStyle(
      color: inactiveColor,
      fontSize: 18,
    );
  }
}
