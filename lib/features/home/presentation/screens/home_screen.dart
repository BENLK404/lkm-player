import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musio/core/routing/app_router.dart';
import 'package:musio/features/for_you/presentation/screens/for_you_screen.dart';
import 'package:musio/features/music/data/models/album_model.dart';
import 'package:musio/features/music/data/models/artist_model.dart';
import 'package:musio/features/music/data/models/playlist_model.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:musio/features/playlist/data/system_playlist.dart';
import 'package:musio/shared/widgets/album_art_image.dart';
import 'package:musio/shared/widgets/album_card.dart';
import 'package:musio/shared/widgets/mini_player.dart';
import 'package:musio/shared/widgets/song_tile.dart';

import '../../../player/presentation/providers/audio_player_provider.dart';

// Provider pour le nombre de colonnes dans la grille d'albums
final albumGridColumnsProvider = StateProvider<double>((ref) => 2.0);
// Provider pour le mode d'affichage des chansons (true = liste, false = grille)
final songDisplayModeProvider = StateProvider<bool>((ref) => true);

class OfflineHomeScreen extends ConsumerStatefulWidget {
  const OfflineHomeScreen({super.key});

  @override
  ConsumerState<OfflineHomeScreen> createState() => _OfflineHomeScreenState();
}

class _OfflineHomeScreenState extends ConsumerState<OfflineHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Reconstruit l'AppBar lorsque l'onglet change pour afficher le bon menu
    _tabController.addListener(() => setState(() {}));

    // Demander les permissions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(musicRepositoryProvider).requestPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);
    final isSongList = ref.watch(songDisplayModeProvider);
    final isOnlineEnabled = ref.watch(onlineFeatureEnabledProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LKM Player'),
        centerTitle: false,
        actions: [
          if (isOnlineEnabled)
            IconButton(
              icon: const Icon(Icons.public),
              tooltip: 'Découvrir en ligne',
              onPressed: () => context.push(AppRouter.online),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRouter.search),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) {
              final menuItems = <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: 'scan',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 12),
                      Text('Rescanner la bibliothèque'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 12),
                      Text('Paramètres'),
                    ],
                  ),
                ),
              ];

              // Ajoute l'option de bascule pour l'onglet "Chansons"
              if (_tabController.index == 1) {
                menuItems.addAll([
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle_song_view',
                    child: Row(
                      children: [
                        Icon(isSongList ? Icons.grid_view : Icons.list),
                        const SizedBox(width: 12),
                        Text(isSongList ? 'Vue grille' : 'Vue liste'),
                      ],
                    ),
                  ),
                ]);
              }

              // Ajoute l'option de réglage pour l'onglet "Albums"
              if (_tabController.index == 2) {
                menuItems.addAll([
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'album_grid_size',
                    child: Row(
                      children: [
                        Icon(Icons.grid_view),
                        SizedBox(width: 12),
                        Text('Taille de la grille'),
                      ],
                    ),
                  ),
                ]);
              }

              return menuItems;
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.start,
          indicatorColor: Theme.of(context).colorScheme.primary,
          dividerColor: Theme.of(context).colorScheme.surface,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pour Moi'),
            Tab(text: 'Chansons'),
            Tab(text: 'Albums'),
            Tab(text: 'Artistes'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: musicState.when(
        data: (state) {
          if (state.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scan de la bibliothèque en cours...'),
                ],
              ),
            );
          }

          if (state.songs.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const ForYouScreen(),
                    _buildSongsTab(state.songs),
                    _buildAlbumsTab(state.albums),
                    _buildArtistsTab(state.artists),
                    _buildPlaylistsTab(state.playlists, state.songs),
                  ],
                ),
              ),
              const MiniPlayer(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(musicProvider.notifier).rescanLibrary(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongsTab(List<SongModel> songs) {
    final isList = ref.watch(songDisplayModeProvider);

    if (songs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(musicProvider.notifier).rescanLibrary();
      },
      child: isList
          ? ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  playlist: songs,
                  songIndex: index,
                );
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return AlbumCard(
                  album: song.toAlbumModel(),
                  onTap: () {
                    ref.read(audioPlayerProvider.notifier).play(songs, index);
                  },
                );
              },
            ),
    );
  }

  Widget _buildAlbumsTab(List<AlbumModel> albums) {
    final columns = ref.watch(albumGridColumnsProvider);

    if (albums.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(musicProvider.notifier).rescanLibrary();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns.round(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return AlbumCard(album: album);
        },
      ),
    );
  }

  Widget _buildArtistsTab(List<ArtistModel> artists) {
    if (artists.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(musicProvider.notifier).rescanLibrary();
      },
      child: ListView.separated(
        itemCount: artists.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 28,
              child: ClipOval(
                child: AlbumArtImage(
                  albumArtPath: artist.imagePath,
                  songId: artist.songIds.isNotEmpty ? artist.songIds.first : '0',
                  size: 56,
                  placeholderIcon: const Icon(Icons.person, size: 32),
                ),
              ),
            ),
            title: Text(artist.name),
            subtitle: Text('${artist.albumCount} albums • ${artist.trackCount} titres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/artist/${artist.id}'),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsTab(List<PlaylistModel> playlists, List<SongModel> songs) {
    final favoritesCount = songs.where((s) => s.isFavorite).length;
    final recentCount = songs.where((s) => s.lastPlayed != null).length;
    final mostPlayedCount = songs.where((s) => s.playCount > 0).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context, ref),
        label: const Text('Créer une playlist'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          // Playlists système
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PLAYLISTS SYSTÈME',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Text('Favoris'),
            subtitle: Text('$favoritesCount chanson${favoritesCount != 1 ? 's' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/playlist/${SystemPlaylist.favorites}'),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Text('Récemment jouées'),
            subtitle: Text('$recentCount chanson${recentCount != 1 ? 's' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/playlist/${SystemPlaylist.recent}'),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Text('Les plus jouées'),
            subtitle: Text('$mostPlayedCount chanson${mostPlayedCount != 1 ? 's' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/playlist/${SystemPlaylist.mostPlayed}'),
          ),
          const Divider(height: 24),
          // Playlists utilisateur
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'MES PLAYLISTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Créez une playlist avec le bouton +',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...playlists.map((playlist) => ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songIds.length} chanson${playlist.songIds.length != 1 ? 's' : ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/playlist/${playlist.id}'),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nom de la playlist',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref
                      .read(musicProvider.notifier)
                      .createPlaylist(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  void _showAlbumGridSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Taille de la grille'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${ref.watch(albumGridColumnsProvider).round()} colonnes'),
                  Slider(
                    value: ref.watch(albumGridColumnsProvider),
                    min: 2,
                    max: 5,
                    divisions: 3,
                    label: '${ref.watch(albumGridColumnsProvider).round()} colonnes',
                    onChanged: (value) {
                      setState(() {
                        ref.read(albumGridColumnsProvider.notifier).state = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Aucune musique trouvée',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Scannez votre bibliothèque pour commencer'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(musicProvider.notifier).rescanLibrary(),
            icon: const Icon(Icons.refresh),
            label: const Text('Scanner la bibliothèque'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'scan':
        ref.read(musicProvider.notifier).rescanLibrary();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan de la bibliothèque démarré')),
        );
        break;
      case 'settings':
        context.push(AppRouter.settings);
        break;
      case 'toggle_song_view':
        final notifier = ref.read(songDisplayModeProvider.notifier);
        notifier.state = !notifier.state;
        break;
      case 'album_grid_size':
        _showAlbumGridSizeDialog(context, ref);
        break;
    }
  }
}

extension on SongModel {
  AlbumModel toAlbumModel() {
    return AlbumModel(
      id: id,
      name: title,
      artist: artist,
      albumArtPath: albumArtPath,
      year: year,
      songIds: [id],
      trackCount: 1,
    );
  }
}
