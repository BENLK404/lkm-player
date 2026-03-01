import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    // We'll load the color after the build once we have the album
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
      if (album.albumArtPath != null) {
        final imageProvider = FileImage(File(album.albumArtPath!));
        final palette = await PaletteGenerator.fromImageProvider(
          imageProvider,
          maximumColorCount: 10,
        );
        if (mounted) {
          setState(() {
            dominantColor = palette.dominantColor?.color ??
                palette.vibrantColor?.color ??
                palette.mutedColor?.color;
          });
        }
      }
    } catch (_) {
      // Ignore if album not found yet
    }
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

    // Apply the diluted solid color background
    final backgroundColor = dominantColor != null
        ? Color.lerp(
            Theme.of(context).scaffoldBackgroundColor, dominantColor!, 0.15)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // En-tête immersif
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  // Fond uni basé sur la couleur dominante
                  Container(color: backgroundColor),

                  // Contenu de l'en-tête
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40), // Espace pour la status bar
                        // Pochette principale
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
                        // Titre de l'album
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
                        // Artiste
                        Text(
                          album.artist,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  // Métadonnées (Année • Nb titres)
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
                        '${album.trackCount} titres',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bouton Lecture
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
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
                      // Bouton Aléatoire
                      Expanded(
                        child: OutlinedButton(
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shuffle_rounded),
                              SizedBox(width: 8),
                              Text('Aléatoire',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
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
                    // Ensure text contrasts well with potentially dark background
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
                    showIndex: true, // Afficher le numéro de piste
                  ),
                );
              },
              childCount: songs.length,
            ),
          ),

          // Espace pour le mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }
}
