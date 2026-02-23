import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/shared/widgets/album_art_image.dart';

class AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final String? customSubtitle;
  final String? customDetails;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onPlayTap,
    this.customSubtitle,
    this.customDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/album/${album.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), // Coins arrondis modernes
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AlbumArtImage(
                      albumArtPath: album.albumArtPath,
                      songId: album.songIds.isNotEmpty ? album.songIds.first : '0',
                      size: double.infinity,
                      borderRadius: BorderRadius.zero, // Géré par ClipRRect
                      fit: BoxFit.cover,
                      placeholderIcon: const Icon(Icons.album, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // Bouton Play optionnel (pour les playlists par exemple)
                if (onPlayTap != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: onPlayTap,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Album info
          const SizedBox(height: 8), // Espace entre image et texte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  customSubtitle ?? album.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                ),
                if (customDetails != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    customDetails!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
