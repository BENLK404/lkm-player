import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart' as lyric_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/lyrics_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

/// Page plein écran des paroles, style Spotify : fond sombre, paroles centrées
/// qui défilent avec la lecture, ligne actuelle mise en avant.
class LyricsFullScreen extends ConsumerWidget {
  const LyricsFullScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentSong = playerState.currentSong;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: _backgroundColor(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
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

    return Scaffold(
      backgroundColor: _backgroundColor(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond dégradé + flou (style Spotify)
          _buildBackground(context, currentSong.albumArtPath),
          // Contenu
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: lyricsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger les paroles',
                            style: TextStyle(
                              color: Colors.white70,
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

  Color _backgroundColor(BuildContext context) {
    return const Color(0xFF121212);
  }

  Widget _buildBackground(BuildContext context, String? albumArtPath) {
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
              child: Image.file(File(path), fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  color: const Color(0xFF121212).withOpacity(0.75),
                ),
              ),
            ),
          ],
        );
      }(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
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
              'Paroles',
              style: TextStyle(
                color: Colors.white,
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
  ) {
    if (lyrics == null || lyrics.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 72,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune parole disponible',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${currentSong.title} · ${currentSong.artist}',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final lyricModel = lyric_ui.LyricsModelBuilder.create()
        .bindLyricToMain(lyrics)
        .getModel();

    return lyric_ui.LyricsReader(
      model: lyricModel,
      position: positionMs,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      emptyBuilder: () => const SizedBox.shrink(),
      selectLineBuilder: (progress, confirm) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Material(
            color: Colors.white.withOpacity(0.12),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
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
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(Duration(milliseconds: progress)),
                            style: const TextStyle(
                              color: Colors.white,
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
      lyricUi: lyric_ui.UINetease(
        highlight: true,
        defaultSize: 26,
        defaultExtSize: 18,
        otherMainSize: 20,
        bias: 0.5,
        lineGap: 32,
        inlineGap: 12,
        lyricAlign: lyric_ui.LyricAlign.CENTER,
        highlightDirection: lyric_ui.HighlightDirection.LTR,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
