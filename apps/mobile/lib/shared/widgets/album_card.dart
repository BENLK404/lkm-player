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
  /// Pastille nombre de titres sur la pochette (bibliothèque locale).
  final bool showTrackBadge;
  /// Ombre / relief pour la grille « bibliothèque ».
  final bool elevatedStyle;

  const AlbumCard({
    required this.album,
    super.key,
    this.onTap,
    this.onPlayTap,
    this.customSubtitle,
    this.customDetails,
    this.showTrackBadge = false,
    this.elevatedStyle = false,
  });

  int get _effectiveTrackCount =>
      album.trackCount > 0 ? album.trackCount : album.songIds.length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);

    final artCard = Card(
      margin: EdgeInsets.zero,
      elevation: elevatedStyle ? 4 : 1,
      shadowColor: elevatedStyle
          ? scheme.shadow.withValues(alpha: 0.35)
          : scheme.shadow.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: AlbumArtImage(
              albumArtPath: album.albumArtPath,
              songId: album.songIds.isNotEmpty ? album.songIds.first : '0',
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
          if (showTrackBadge && _effectiveTrackCount > 0)
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '$_effectiveTrackCount',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
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
    );

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
              child: artCard,
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
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.8),
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
