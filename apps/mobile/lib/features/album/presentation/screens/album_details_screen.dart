import 'dart:io';

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

class AlbumDetailsScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailsScreen({
    required this.albumId,
    super.key,
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

    final scheme = Theme.of(context).colorScheme;
    final playButtonColor = dominantColor != null
        ? _vibrantButtonColor(dominantColor!, scheme)
        : scheme.primary;

    final heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        if (dominantColor != null)
          dominantColor!.withValues(alpha: 0.4)
        else
          scheme.primaryContainer.withValues(alpha: 0.95),
        scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        scheme.surface,
      ],
    );

    // First song for art display in popup
    final firstSong = songs.isNotEmpty ? songs.first : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: scheme.error),
                onPressed: () => _confirmDeleteAlbum(context, ref, album),
                tooltip: 'Supprimer l\'album',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: heroGradient),
                      ),
                    ),
                    Positioned(
                      left: -24,
                      bottom: -16,
                      child: IgnorePointer(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.tertiary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      scheme.shadow.withValues(alpha: 0.22),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AlbumArtImage(
                                albumArtPath: album.albumArtPath,
                                songId: album.songIds.isNotEmpty
                                    ? album.songIds.first
                                    : '0',
                                size: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            album.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                  color: scheme.onSurface,
                                ),
                          ),
                          if (album.artist.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              album.artist,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (songs.isNotEmpty && songs.first.year != null)
                                _AlbumDetailStatChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: '${songs.first.year}',
                                  scheme: scheme,
                                ),
                              _AlbumDetailStatChip(
                                icon: Icons.audiotrack_rounded,
                                label:
                                    '${album.trackCount} titre${album.trackCount > 1 ? 's' : ''}',
                                scheme: scheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () {
                                          ref
                                              .read(audioPlayerProvider
                                                  .notifier)
                                              .play(songs, 0);
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: playButtonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded),
                                      SizedBox(width: 8),
                                      Text(
                                        'Lecture',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                onPressed: songs.isEmpty
                                    ? null
                                    : () {
                                        ref
                                            .read(audioPlayerProvider
                                                .notifier)
                                            .play(songs, 0);
                                        ref
                                            .read(audioPlayerProvider
                                                .notifier)
                                            .toggleShuffle();
                                      },
                                icon: const Icon(Icons.shuffle_rounded),
                                tooltip: 'Lecture aléatoire',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _albumSectionHeader(context, 'Morceaux'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  playlist: songs,
                  songIndex: index,
                  showIndex: true,
                );
              },
              childCount: songs.length,
            ),
          ),
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
            child: SizedBox(height: 100),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _albumSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _AlbumDetailStatChip extends StatelessWidget {
  const _AlbumDetailStatChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
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
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              info.extract,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onArtistTap,
              child: Text(
                'Voir plus',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
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
                                decoration: const BoxDecoration(
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
                            return const Padding(
                              padding: EdgeInsets.all(20),
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
