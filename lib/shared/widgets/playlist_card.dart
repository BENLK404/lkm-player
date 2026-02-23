import 'package:flutter/material.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/shared/widgets/album_art_image.dart';

class PlaylistCard extends StatelessWidget {
  final AlbumModel playlist;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final String details;
  final List<String?> albumArtPaths; // Liste des chemins d'images pour la mosaïque

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.onPlayTap,
    required this.details,
    required this.albumArtPaths,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack pour l'effet "pile"
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Carte arrière
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Carte milieu
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Carte principale (Mosaïque)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildMosaic(context),
                      ),
                      // Overlay dégradé
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bouton Play
                      if (onPlayTap != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: onPlayTap,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosaic(BuildContext context) {
    // Filtrer les chemins nuls
    final validPaths = albumArtPaths.where((path) => path != null).take(4).toList();

    if (validPaths.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.queue_music, size: 50, color: Colors.grey),
        ),
      );
    }

    if (validPaths.length < 4) {
      // Si moins de 4 images, on affiche la première en grand
      return AlbumArtImage(
        albumArtPath: validPaths.first,
        songId: 'playlist_cover', // ID fictif
        size: double.infinity,
        borderRadius: BorderRadius.zero,
        fit: BoxFit.cover,
      );
    }

    // Sinon, on affiche une grille 2x2
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: AlbumArtImage(
                  albumArtPath: validPaths[0],
                  songId: 'p1',
                  size: double.infinity,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: AlbumArtImage(
                  albumArtPath: validPaths[1],
                  songId: 'p2',
                  size: double.infinity,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: AlbumArtImage(
                  albumArtPath: validPaths[2],
                  songId: 'p3',
                  size: double.infinity,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: AlbumArtImage(
                  albumArtPath: validPaths[3],
                  songId: 'p4',
                  size: double.infinity,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
