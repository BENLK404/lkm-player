import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/album_card.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class ArtistDetailsScreen extends ConsumerWidget {
  final String artistId;

  const ArtistDetailsScreen({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(allArtistsProvider);
    final songs = ref.watch(artistSongsProvider(artistId));
    final albums = ref.watch(allAlbumsProvider);

    if (artists.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final artist = artists.firstWhere((a) => a.id == artistId);
    
    // Gestion intelligente du chargement pour éviter le clignotement
    // On utilise directement la liste retournée par le provider synchrone
    if (songs.isEmpty) {
       // Si la liste est vide, on peut afficher un message ou un loader si on sait que ça charge
       // Mais comme le provider est synchrone, s'il est vide c'est qu'il n'y a pas de chansons
    }

    final artistAlbums = albums
        .where((album) => album.artist == artist.name)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec photo artiste
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: AlbumArtImageLarge(
                songId: artist.songIds.isNotEmpty ? artist.songIds.first : '0',
                albumArtPath: artist.imagePath,
                heroTag: 'artist-art-${artist.id}',
                // placeholderIcon: const Icon(Icons.person, size: 100),
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
                  _buildStat(
                      context, artist.albumCount.toString(), 'Albums'),
                  _buildStat(
                      context, artist.trackCount.toString(), 'Chansons'),
                ],
              ),
            ),
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
                        ref
                            .read(audioPlayerProvider.notifier)
                            .play(songs, 0);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lire tout'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .play(songs, 0);
                        ref
                            .read(audioPlayerProvider.notifier)
                            .toggleShuffle();
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Mélanger'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
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
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
              ),
            ),
          ),

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

          // Albums
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Albums',
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = artistAlbums[index];
                  return AlbumCard(album: album);
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
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
