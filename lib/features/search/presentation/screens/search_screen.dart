import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher une chanson, un album, un artiste...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: musicState.when(
        data: (state) {
          if (_searchQuery.isEmpty) {
            return _buildEmptyState();
          }

          final filteredSongs = state.songs.where((song) {
            return song.title.toLowerCase().contains(_searchQuery) ||
                   song.artist.toLowerCase().contains(_searchQuery) ||
                   song.album.toLowerCase().contains(_searchQuery);
          }).toList();

          final filteredAlbums = state.albums.where((album) {
            return album.name.toLowerCase().contains(_searchQuery) ||
                   album.artist.toLowerCase().contains(_searchQuery);
          }).toList();

          final filteredArtists = state.artists.where((artist) {
            return artist.name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredSongs.isEmpty && filteredAlbums.isEmpty && filteredArtists.isEmpty) {
            return _buildNoResults();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Artistes
                    if (filteredArtists.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Artistes', filteredArtists.length),
                      ...filteredArtists.take(3).map((artist) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            artist.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(artist.name),
                        subtitle: Text('${artist.albumCount} albums'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Naviguer vers l'artiste
                        },
                      )),
                      if (filteredArtists.length > 3)
                        TextButton(
                          onPressed: () {
                            // TODO: Voir tous les artistes
                          },
                          child: Text('Voir tous les ${filteredArtists.length} artistes'),
                        ),
                      const Divider(),
                    ],

                    // Albums
                    if (filteredAlbums.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Albums', filteredAlbums.length),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAlbums.take(10).length,
                          itemBuilder: (context, index) {
                            final album = filteredAlbums[index];
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.album, size: 48),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    album.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    album.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],

                    // Chansons
                    if (filteredSongs.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Chansons', filteredSongs.length),
                      ...filteredSongs.map((song) {
                        final songIndex = filteredSongs.indexOf(song);
                        return SongTile(
                          song: song,
                          playlist: filteredSongs,
                          songIndex: songIndex,
                        );
                      }),
                    ],

                    // Espace pour le mini player
                    const SizedBox(height: 72),
                  ],
                ),
              ),
              const MiniPlayer(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Rechercher dans votre bibliothèque',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez vos chansons, albums et artistes préférés',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
