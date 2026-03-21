import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/artist/presentation/providers/artist_wikipedia_provider.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

class AlbumDetailsScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailsScreen({
    super.key,
    required this.albumId,
  });

  @override
  ConsumerState<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends ConsumerState<AlbumDetailsScreen> {
  Color? dominantColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDominantColor();
    });
  }

  Future<void> _confirmDeleteAlbum(
    BuildContext context,
    WidgetRef ref,
    AlbumModel album,
  ) async {
    final playerState = ref.read(audioPlayerProvider);
    final currentIds = playerState.queue.map((s) => s.id).toSet();
    final albumSongIds =
        ref.read(albumSongsProvider(album.id)).map((s) => s.id).toSet();
    final isCurrentAlbumPlaying =
        albumSongIds.any((id) => currentIds.contains(id));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'album ?'),
        content: Text(
          '« ${album.name} » et ses ${album.trackCount} titre(s) seront supprimés de la bibliothèque. Les fichiers seront supprimés du téléphone.'
          '${isCurrentAlbumPlaying ? '\n\nLa lecture en cours sera arrêtée.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final albumName = album.name;
    final albumIdToRemove = album.id;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (isCurrentAlbumPlaying) {
          await ref.read(audioPlayerProvider.notifier).stop();
        }
        await ref.read(musicProvider.notifier).removeAlbum(albumIdToRemove);
        messenger.showSnackBar(
          SnackBar(content: Text('Album « $albumName » supprimé')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
        await ref.read(musicProvider.notifier).loadFromCache();
      }
    });
  }

  Future<void> _loadDominantColor() async {
    final albums = ref.read(allAlbumsProvider);
    try {
      final album = albums.firstWhere((a) => a.id == widget.albumId);
      if (album.albumArtPath == null) return;
      final path = album.albumArtPath!;
      final ImageProvider imageProvider = path.startsWith('content://')
          ? ResizeImage(NetworkImage(path), width: 80, height: 80)
          : ResizeImage(FileImage(File(path)), width: 80, height: 80);
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 8,
      );
      if (mounted) {
        setState(() {
          dominantColor = palette.vibrantColor?.color ??
              palette.dominantColor?.color ??
              palette.mutedColor?.color;
        });
      }
    } catch (_) {}
  }

  Color _vibrantButtonColor(Color base, ColorScheme scheme) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.35, 0.55))
        .toColor();
  }

  void _showArtistPopup(BuildContext context, String artistName,
      String? albumArtPath, String? songId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Artiste',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, secondAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) {
        return _ArtistPopup(
          artistName: artistName,
          albumArtPath: albumArtPath,
          songId: songId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(allAlbumsProvider);
    final songs = ref.watch(albumSongsProvider(widget.albumId));

    if (albums.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final albumIndex = albums.indexWhere((a) => a.id == widget.albumId);
    if (albumIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final album = albums[albumIndex];

    final backgroundColor = dominantColor != null
        ? Color.lerp(
            Theme.of(context).scaffoldBackgroundColor, dominantColor!, 0.35)!
        : Theme.of(context).scaffoldBackgroundColor;
    final playButtonColor = dominantColor != null
        ? _vibrantButtonColor(dominantColor!, Theme.of(context).colorScheme)
        : Theme.of(context).colorScheme.primary;

    // First song for art display in popup
    final firstSong = songs.isNotEmpty ? songs.first : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // En-tête immersif
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: backgroundColor,
            actions: [
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () => _confirmDeleteAlbum(context, ref, album),
                tooltip: 'Supprimer l\'album',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AlbumArtImage(
                              albumArtPath: album.albumArtPath,
                              songId: album.songIds.isNotEmpty
                                  ? album.songIds.first
                                  : '0',
                              size: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            album.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Artiste — affichage simple
                        if (album.artist.isNotEmpty)
                          Text(
                            album.artist,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                ),
                          )
                        else
                          Text(
                            album.artist,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Informations et Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (songs.isNotEmpty && songs.first.year != null)
                        Text(
                          '${songs.first.year} • ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white60),
                        ),
                      Text(
                        '${album.trackCount} titre${album.trackCount > 1 ? 's' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (songs.isNotEmpty) {
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .play(songs, 0);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: playButtonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded),
                              SizedBox(width: 8),
                              Text('Lecture',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (songs.isNotEmpty) {
                            ref
                                .read(audioPlayerProvider.notifier)
                                .play(songs, 0);
                            ref
                                .read(audioPlayerProvider.notifier)
                                .toggleShuffle();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.shuffle_rounded)],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Liste des chansons
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = songs[index];
                return Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: Colors.white,
                          displayColor: Colors.white,
                        ),
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  child: SongTile(
                    song: song,
                    playlist: songs,
                    songIndex: index,
                    showIndex: true,
                  ),
                );
              },
              childCount: songs.length,
            ),
          ),

          // Divider(
          //   color: Colors.white12,
          //   thickness: 1,
          // ),

          // === BIO ARTISTE WIKIPEDIA (en bas de la liste) ===
          if (album.artist.isNotEmpty && songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: _WikiDescriptionText(
                  artistName: album.artist,
                  onArtistTap: () => _showArtistPopup(
                    context,
                    album.artist,
                    firstSong?.albumArtPath,
                    firstSong?.id,
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }
}

/// Affiche la description Wikipedia en 2 lignes avec "voir plus".
class _WikiDescriptionText extends ConsumerWidget {
  final String artistName;
  final VoidCallback onArtistTap;

  const _WikiDescriptionText({
    required this.artistName,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(artistWikipediaInfoProvider(artistName));

    return asyncInfo.when(
      data: (info) {
        if (info == null || info.extract.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À propos de $artistName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              info.extract,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onArtistTap,
              child: Text(
                'Voir plus',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Popup noir avec image artiste (moitié haute) + bio Wikipedia (moitié basse).
class _ArtistPopup extends ConsumerWidget {
  final String artistName;
  final String? albumArtPath;
  final String? songId;

  const _ArtistPopup({
    required this.artistName,
    required this.albumArtPath,
    required this.songId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(artistWikipediaInfoProvider(artistName));
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
              constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === IMAGE ARTISTE (moitié supérieure) ===
                    SizedBox(
                      height: screenHeight * 0.35,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildArtImage(),
                          // Gradient bottom
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.5, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF0A0A0A),
                                ],
                              ),
                            ),
                          ),
                          // Close button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Artist name overlay
                          Positioned(
                            bottom: 16,
                            left: 20,
                            right: 20,
                            child: Text(
                              artistName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 10, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // === BIO WIKIPEDIA (scrollable) ===
                    Flexible(
                      child: asyncInfo.when(
                        data: (info) {
                          if (info == null || info.extract.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Aucune information disponible sur Wikipedia.',
                                style: TextStyle(color: Colors.white38),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info.extract,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Impossible de charger les informations.',
                            style: TextStyle(color: Colors.white38),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtImage() {
    if (albumArtPath == null) return _artPlaceholder();
    if (albumArtPath!.startsWith('content://')) {
      return Image.network(
        albumArtPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _artPlaceholder(),
      );
    }
    final file = File(albumArtPath!);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _artPlaceholder(),
      );
    }
    return _artPlaceholder();
  }

  Widget _artPlaceholder() => Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Text(
            artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white12,
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
