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
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap ?? () => context.push('/album/${album.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: radius),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AlbumArtImage(
                        albumArtPath: album.albumArtPath,
                        songId:
                            album.songIds.isNotEmpty ? album.songIds.first : '0',
                        size: double.infinity,
                        borderRadius: BorderRadius.zero,
                        fit: BoxFit.cover,
                        placeholderIcon: Icon(
                          Icons.album,
                          size: 50,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    if (onPlayTap != null)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: FilledButton(
                          onPressed: onPlayTap,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 44),
                          ),
                          child: const Icon(Icons.play_arrow_rounded),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customSubtitle ?? album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (customDetails != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customDetails!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
