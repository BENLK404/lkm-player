import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/presentation/providers/metadata_provider.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class AlbumDetailsScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailsScreen({
    super.key,
    required this.albumId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(allAlbumsProvider);
    final songs = ref.watch(albumSongsProvider(albumId));

    if (albums.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final album = albums.firstWhere(
      (a) => a.id == albumId,
      orElse: () => throw Exception('Album non trouvé'),
    );

    final firstSongPath = songs.isNotEmpty ? songs.first.path : null;
    final metadataAsyncValue = firstSongPath != null
        ? ref.watch(songMetadataProvider(firstSongPath))
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // En-tête immersif
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond floutée
                  if (album.albumArtPath != null)
                    Image.file(
                      File(album.albumArtPath!),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Theme.of(context).colorScheme.primaryContainer),
                  
                  // Flou
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                    ),
                  ),

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
                              songId: album.songIds.isNotEmpty ? album.songIds.first : '0',
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Artiste
                        Text(
                          album.artist,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
                      if (metadataAsyncValue != null)
                        metadataAsyncValue.when(
                          data: (metadata) {
                            final year = metadata?.year;
                            if (year != null && year.isNotEmpty) {
                              return Text(
                                '$year • ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      Text(
                        '${album.trackCount} titres',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
                              ref.read(audioPlayerProvider.notifier).play(songs, 0);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
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
                              Text('Lecture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              ref.read(audioPlayerProvider.notifier).play(songs, 0);
                              ref.read(audioPlayerProvider.notifier).toggleShuffle();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shuffle_rounded),
                              SizedBox(width: 8),
                              Text('Aléatoire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                return SongTile(
                  song: song,
                  playlist: songs,
                  songIndex: index,
                  showIndex: true, // Afficher le numéro de piste
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
