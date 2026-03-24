import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/features/artist/presentation/providers/artist_wikipedia_provider.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/album_card.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';
import 'package:palette_generator/palette_generator.dart';

class ArtistDetailsScreen extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistDetailsScreen({
    required this.artistId,
    super.key,
  });

  @override
  ConsumerState<ArtistDetailsScreen> createState() =>
      _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends ConsumerState<ArtistDetailsScreen> {
  Color? dominantColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDominantColor();
    });
  }

  Future<void> _loadDominantColor() async {
    final artists = ref.read(allArtistsProvider);
    try {
      final artist = artists.firstWhere((a) => a.id == widget.artistId);
      if (artist.imagePath != null) {
        final imageProvider = FileImage(File(artist.imagePath!));
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final artists = ref.watch(allArtistsProvider);
    final songs = ref.watch(artistSongsProvider(widget.artistId));
    final albums = ref.watch(allAlbumsProvider);

    if (artists.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final artist = artists.firstWhere((a) => a.id == widget.artistId);
    final artistAlbums =
        albums.where((album) => album.artist == artist.name).toList();

    final heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        if (dominantColor != null)
          dominantColor!.withValues(alpha: 0.45)
        else
          scheme.primaryContainer.withValues(alpha: 0.9),
        scheme.surfaceContainerHighest.withValues(alpha: 0.95),
        scheme.surface,
      ],
    );

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
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                      right: -30,
                      top: -20,
                      child: IgnorePointer(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      child: Center(
                        child: Hero(
                          tag: 'artist-art-${artist.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.shadow.withValues(alpha: 0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AlbumArtImageLarge(
                                  songId: artist.songIds.isNotEmpty
                                      ? artist.songIds.first
                                      : '0',
                                  albumArtPath: artist.imagePath,
                                  size: 200,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _DetailStatChip(
                    icon: Icons.album_rounded,
                    label:
                        '${artist.albumCount} album${artist.albumCount != 1 ? 's' : ''}',
                    scheme: scheme,
                  ),
                  _DetailStatChip(
                    icon: Icons.audiotrack_rounded,
                    label:
                        '${artist.trackCount} titre${artist.trackCount != 1 ? 's' : ''}',
                    scheme: scheme,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 32,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              indent: 20,
              endIndent: 20,
            ),
          ),
          SliverToBoxAdapter(
            child: _WikipediaSection(artistName: artist.name),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .play(songs, 0);
                            },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Lire tout'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .play(songs, 0);
                              ref
                                  .read(audioPlayerProvider.notifier)
                                  .toggleShuffle();
                            },
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Mélanger'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _sectionHeader(context, 'Top chansons'),
          ),
          if (songs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun morceau pour cet artiste.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
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
          if (artistAlbums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _sectionHeader(context, 'Albums'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final album = artistAlbums[index];
                    return AlbumCard(
                      album: album,
                      showTrackBadge: true,
                      elevatedStyle: true,
                    );
                  },
                  childCount: artistAlbums.length,
                ),
              ),
            ),
          ] else
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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

class _DetailStatChip extends StatelessWidget {
  const _DetailStatChip({
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
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

/// Section affichant la biographie de l'artiste depuis Wikipedia (cache puis API).
class _WikipediaSection extends ConsumerWidget {
  const _WikipediaSection({required this.artistName});

  final String artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncInfo = ref.watch(artistWikipediaInfoProvider(artistName));
    return asyncInfo.when(
      data: (info) {
        if (info == null || info.extract.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'À propos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                info.extract,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
