import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/album_model.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/music_repository.dart';

part 'music_provider.freezed.dart';
part 'music_provider.g.dart';

@freezed
class MusicLibraryState with _$MusicLibraryState {
  const factory MusicLibraryState({
    @Default(false) bool isLoading,
    @Default([]) List<SongModel> songs,
    @Default([]) List<AlbumModel> albums,
    @Default([]) List<ArtistModel> artists,
    @Default([]) List<PlaylistModel> playlists,
  }) = _MusicLibraryState;
}

@Riverpod(keepAlive: true)
class Music extends _$Music {
  @override
  Future<MusicLibraryState> build() async {
    // Charger depuis le cache au démarrage
    await loadFromCache();
    return state.value ?? const MusicLibraryState();
  }

  Future<void> loadFromCache() async {
    final repository = ref.read(musicRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      // Charger uniquement depuis le cache
      final songs = await repository.getSongsFromCache();
      final albums = await repository.getAlbumsFromCache();
      final artists = await repository.getArtistsFromCache();
      final playlists = await repository.getPlaylistsFromCache();

      state = AsyncValue.data(MusicLibraryState(
        songs: songs,
        albums: albums,
        artists: artists,
        playlists: playlists,
        isLoading: false,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> rescanLibrary() async {
    final repository = ref.read(musicRepositoryProvider);
    
    // Garder l'état actuel mais mettre isLoading à true
    final currentState = state.valueOrNull ?? const MusicLibraryState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      // Lancer le scan complet
      final songs = await repository.scanAndCacheSongs();
      
      // Recharger les autres données qui dépendent des chansons
      final albums = await repository.getAlbumsFromCache();
      final artists = await repository.getArtistsFromCache();
      final playlists = await repository.getPlaylistsFromCache();

      state = AsyncValue.data(MusicLibraryState(
        songs: songs,
        albums: albums,
        artists: artists,
        playlists: playlists,
        isLoading: false,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> recordSongPlayed(SongModel song) async {
    final repository = ref.read(musicRepositoryProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedSong = song.copyWith(
      playCount: song.playCount + 1,
      lastPlayed: DateTime.now(),
    );

    // Mettre à jour l'état local
    final updatedSongs = currentState.songs
        .map((s) => s.id == song.id ? updatedSong : s)
        .toList();
    state = AsyncValue.data(currentState.copyWith(songs: updatedSongs));

    // Sauvegarder dans Hive
    await repository.updateSong(updatedSong);
  }

  Future<void> toggleFavoriteStatus(SongModel song) async {
    final repository = ref.read(musicRepositoryProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedSong = song.copyWith(isFavorite: !song.isFavorite);

    // Mettre à jour l'état local
    final updatedSongs = currentState.songs
        .map((s) => s.id == song.id ? updatedSong : s)
        .toList();
    state = AsyncValue.data(currentState.copyWith(songs: updatedSongs));

    // Sauvegarder dans Hive
    await repository.updateSong(updatedSong);
  }

  Future<void> createPlaylist(String name) async {
    final repository = ref.read(musicRepositoryProvider);
    final newPlaylist = PlaylistModel.create(name: name);
    await repository.createPlaylist(newPlaylist);
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(
          currentState.copyWith(playlists: [...currentState.playlists, newPlaylist]));
    }
  }

  Future<void> addSongToPlaylist(String songId, String playlistId) async {
    final repository = ref.read(musicRepositoryProvider);
    await repository.addSongToPlaylist(songId, playlistId);
    // Refresh playlists from source
    final playlists = await repository.getPlaylistsFromCache();
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(playlists: playlists));
    }
  }

  Future<void> removeSongFromPlaylist(String songId, String playlistId) async {
    final repository = ref.read(musicRepositoryProvider);
    await repository.removeSongFromPlaylist(songId, playlistId);
    // Refresh playlists from source
    final playlists = await repository.getPlaylistsFromCache();
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(playlists: playlists));
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final repository = ref.read(musicRepositoryProvider);
    await repository.deletePlaylist(playlistId);
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
          playlists:
              currentState.playlists.where((p) => p.id != playlistId).toList()));
    }
  }

  Future<void> clearArtworkCache() async {
    final repository = ref.read(musicRepositoryProvider);
    await repository.clearArtworkCache();
  }
}

/// Provider singleton pour le repository music
@Riverpod(keepAlive: true)
MusicRepository musicRepository(MusicRepositoryRef ref) {
  return MusicRepository(ref);
}

/// Provider pour toutes les chansons (Synchrone)
@riverpod
List<SongModel> allSongs(AllSongsRef ref) {
  final musicState = ref.watch(musicProvider);
  return musicState.valueOrNull?.songs ?? [];
}

/// Provider pour tous les albums (Synchrone)
@riverpod
List<AlbumModel> allAlbums(AllAlbumsRef ref) {
  final musicState = ref.watch(musicProvider);
  return musicState.valueOrNull?.albums ?? [];
}

/// Provider pour tous les artistes (Synchrone)
@riverpod
List<ArtistModel> allArtists(AllArtistsRef ref) {
  final musicState = ref.watch(musicProvider);
  return musicState.valueOrNull?.artists ?? [];
}

/// Provider pour les chansons d'un album spécifique (Synchrone)
@riverpod
List<SongModel> albumSongs(AlbumSongsRef ref, String albumId) {
  final musicState = ref.watch(musicProvider);
  return musicState.valueOrNull?.songs.where((s) => s.albumId == albumId).toList() ?? [];
}

/// Provider pour les chansons d'un artiste spécifique (Synchrone)
@riverpod
List<SongModel> artistSongs(ArtistSongsRef ref, String artistId) {
  final musicState = ref.watch(musicProvider);
  return musicState.valueOrNull?.songs.where((s) => s.artistId == artistId).toList() ?? [];
}

/// Provider pour rechercher des chansons (Synchrone)
@riverpod
List<SongModel> searchSongs(SearchSongsRef ref, String query) {
  if (query.isEmpty) {
    return [];
  }
  final musicState = ref.watch(musicProvider);
  final songs = musicState.valueOrNull?.songs ?? [];
  final lowerQuery = query.toLowerCase();
  return songs
      .where((song) =>
          song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery))
      .toList();
}

@riverpod
Future<String?> lyrics(LyricsRef ref, String songId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return repository.getLyrics(songId);
}
