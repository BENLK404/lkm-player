import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/shared/widgets/album_card.dart';

import '../providers/home_tab_providers.dart';

/// Onglet Albums : en-tête visuel + grille (remplace la simple GridView).
class OfflineAlbumsLibrary extends ConsumerWidget {
  const OfflineAlbumsLibrary({
    super.key,
    required this.albums,
    required this.onRefresh,
  });

  final List<AlbumModel> albums;
  final Future<void> Function() onRefresh;

  int _totalTracks(List<AlbumModel> list) {
    var n = 0;
    for (final a in list) {
      if (a.trackCount > 0) {
        n += a.trackCount;
      } else {
        n += a.songIds.length;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(albumGridColumnsProvider).round().clamp(2, 5);
    final selectionMode = ref.watch(selectionModeProvider);
    final selectedIds = ref.watch(selectedAlbumIdsProvider);
    final isAlbumSelection = selectionMode == 'albums';
    final scheme = Theme.of(context).colorScheme;
    final totalTracks = _totalTracks(albums);

    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _AlbumsHeroHeader(
              albumCount: albums.length,
              trackCount: totalTracks,
              selectionMode: isAlbumSelection,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                      isAlbumSelection
                          ? 'Sélectionnez des albums'
                          : 'Tous les albums',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 20,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = albums[index];
                  final isSelected = selectedIds.contains(album.id);
                  if (isAlbumSelection) {
                    return InkWell(
                      onTap: () {
                        final next = Set<String>.from(selectedIds);
                        if (isSelected) {
                          next.remove(album.id);
                        } else {
                          next.add(album.id);
                        }
                        ref.read(selectedAlbumIdsProvider.notifier).state =
                            next;
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          AlbumCard(
                            album: album,
                            onTap: () {},
                            showTrackBadge: true,
                            elevatedStyle: true,
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Material(
                              color: scheme.surface.withValues(alpha: 0.9),
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  value: isSelected,
                                  onChanged: (_) {
                                    final next = Set<String>.from(selectedIds);
                                    if (isSelected) {
                                      next.remove(album.id);
                                    } else {
                                      next.add(album.id);
                                    }
                                    ref
                                        .read(selectedAlbumIdsProvider.notifier)
                                        .state = next;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GestureDetector(
                    onLongPress: () {
                      ref.read(selectionModeProvider.notifier).state =
                          'albums';
                      ref.read(selectedSongIdsProvider.notifier).state = {};
                      ref.read(selectedAlbumIdsProvider.notifier).state = {
                        album.id
                      };
                    },
                    child: AlbumCard(
                      album: album,
                      showTrackBadge: true,
                      elevatedStyle: true,
                    ),
                  );
                },
                childCount: albums.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumsHeroHeader extends StatelessWidget {
  const _AlbumsHeroHeader({
    required this.albumCount,
    required this.trackCount,
    required this.selectionMode,
  });

  final int albumCount;
  final int trackCount;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              scheme.primary.withValues(alpha: 0.35),
              scheme.tertiaryContainer.withValues(alpha: 0.4),
              scheme.surfaceContainerHighest.withValues(alpha: 0.9),
            ]
          : [
              scheme.primaryContainer.withValues(alpha: 0.95),
              scheme.secondaryContainer.withValues(alpha: 0.55),
              scheme.surface.withValues(alpha: 1),
            ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            // Halos décoratifs
            Positioned(
              right: -40,
              top: -50,
              child: IgnorePointer(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -20,
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
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.album_rounded,
                          size: 32,
                          color: scheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!selectionMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.offline_bolt_rounded,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Hors ligne',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    selectionMode ? 'MODE SÉLECTION' : 'COLLECTION LOCALE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectionMode ? 'Albums' : 'Tes albums',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.library_music_rounded,
                        label:
                            '$albumCount album${albumCount != 1 ? 's' : ''}',
                        scheme: scheme,
                      ),
                      _StatChip(
                        icon: Icons.audiotrack_rounded,
                        label:
                            '$trackCount titre${trackCount != 1 ? 's' : ''}',
                        scheme: scheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
