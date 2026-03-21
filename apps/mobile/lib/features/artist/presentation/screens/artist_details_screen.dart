import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    super.key,
    required this.artistId,
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
        // Here we ideally want to load the image from file, but artist image logic in MusicService
        // uses album art path of its first song.
        // The UI uses AlbumArtImageLarge to resolve this.
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
    final artists = ref.watch(allArtistsProvider);
    final songs = ref.watch(artistSongsProvider(widget.artistId));
    final albums = ref.watch(allAlbumsProvider);

    if (artists.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final artist = artists.firstWhere((a) => a.id == widget.artistId);

    // Gestion intelligente du chargement pour éviter le clignotement
    // On utilise directement la liste retournée par le provider synchrone
    if (songs.isEmpty) {
      // Si la liste est vide, on peut afficher un message ou un loader si on sait que ça charge
      // Mais comme le provider est synchrone, s'il est vide c'est qu'il n'y a pas de chansons
    }

    final artistAlbums =
        albums.where((album) => album.artist == artist.name).toList();

    // Apply the diluted solid color background
    final backgroundColor = dominantColor != null
        ? Color.lerp(
            Theme.of(context).scaffoldBackgroundColor, dominantColor!, 0.15)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar avec photo artiste
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: backgroundColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: backgroundColor),
                  AlbumArtImageLarge(
                    songId:
                        artist.songIds.isNotEmpty ? artist.songIds.first : '0',
                    albumArtPath: artist.imagePath,
                    heroTag: 'artist-art-${artist.id}',
                    // placeholderIcon: const Icon(Icons.person, size: 100),
                  ),
                  // Slight gradient to make text readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Statistiques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, artist.albumCount.toString(), 'Albums'),
                  _buildStat(context, artist.trackCount.toString(), 'Chansons'),
                ],
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
          ),

          // Biographie Wikipedia (cache + API)
          SliverToBoxAdapter(
            child: _WikipediaSection(artistName: artist.name),
          ),

          // Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).play(songs, 0);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lire tout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).play(songs, 0);
                        ref.read(audioPlayerProvider.notifier).toggleShuffle();
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Mélanger'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top chansons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Top chansons',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
          ),

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

          // Albums
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Albums',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = artistAlbums[index];
                  // Temporarily ignore text coloring for album card inside
                  return Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.apply(
                              bodyColor: Colors.white,
                              displayColor: Colors.white,
                            ),
                      ),
                      child: AlbumCard(album: album));
                },
                childCount: artistAlbums.length,
              ),
            ),
          ),

          // Espace pour le mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 72),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).colorScheme.primary, // Apple music pink
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

/// Section affichant la biographie de l'artiste depuis Wikipedia (cache puis API).
class _WikipediaSection extends ConsumerWidget {
  const _WikipediaSection({required this.artistName});

  final String artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(artistWikipediaInfoProvider(artistName));
    return asyncInfo.when(
      data: (info) {
        if (info == null || info.extract.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'À propos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                info.extract,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
