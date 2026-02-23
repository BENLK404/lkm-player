import 'dart:convert';
import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as aq;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

/// Repository gérant l'accès aux données musicales
class MusicRepository {
  final aq.OnAudioQuery _audioQuery = aq.OnAudioQuery();
  final Audiotagger _tagger = Audiotagger();
  late Box<SongModel> _songBox;
  late Box<PlaylistModel> _playlistBox;
  late Box _lyricsCacheBox;

  Directory? _artworkCacheDir;
  final Ref _ref;

  MusicRepository(this._ref) {
    _songBox = Hive.box<SongModel>('songs');
    _playlistBox = Hive.box<PlaylistModel>('playlists');
    _lyricsCacheBox = Hive.box('lyrics_cache');
  }

  /// Initialiser le répertoire de cache pour les artworks
  Future<void> _initArtworkCache() async {
    if (_artworkCacheDir != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    _artworkCacheDir = Directory(path.join(appDir.path, 'album_artworks'));

    if (!await _artworkCacheDir!.exists()) {
      await _artworkCacheDir!.create(recursive: true);
    }
  }

  /// Demander les permissions de stockage
  Future<bool> requestPermissions() async {
    try {
      if (await Permission.audio.status.isDenied) {
        final audioStatus = await Permission.audio.request();
        if (!audioStatus.isGranted) return false;
      }
      // Demander la permission de notification (Android 13+)
      if (await Permission.notification.status.isDenied) {
        await Permission.notification.request();
      }
      
      if (await Permission.storage.status.isDenied) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (await Permission.audio.status.isGranted) return true;
          return false;
        }
      }
      
      return true;
    } on PlatformException catch (e) {
      AppLogger.e('Erreur lors de la demande de permissions', error: e);
      return false;
    } catch (e) {
      AppLogger.e('Erreur inattendue lors de la demande de permissions', error: e);
      return false;
    }
  }

  // --- MÉTHODES DE CACHE (Lecture seule, pas de scan) ---

  Future<List<SongModel>> getSongsFromCache() async {
    return _songBox.values.toList();
  }

  Future<List<AlbumModel>> getAlbumsFromCache() async {
    final songs = _songBox.values.toList();
    final albumMap = <String, AlbumModel>{};

    for (var song in songs) {
      if (song.albumId != null) {
        if (!albumMap.containsKey(song.albumId)) {
          albumMap[song.albumId!] = AlbumModel(
            id: song.albumId!,
            name: song.album,
            artist: song.artist,
            albumArtPath: song.albumArtPath,
            year: song.year,
            songIds: [],
            trackCount: 0,
          );
        }
        final album = albumMap[song.albumId!]!;
        albumMap[song.albumId!] = album.copyWith(
          songIds: [...album.songIds, song.id],
          trackCount: album.trackCount + 1,
        );
      }
    }
    return albumMap.values.toList();
  }

  Future<List<ArtistModel>> getArtistsFromCache() async {
    final songs = _songBox.values.toList();
    final artistMap = <String, ArtistModel>{};

    for (var song in songs) {
      if (song.artistId != null) {
        if (!artistMap.containsKey(song.artistId)) {
          final artwork = songs
              .firstWhere(
                (s) => s.artistId == song.artistId && s.albumArtPath != null,
                orElse: () => song,
              )
              .albumArtPath;

          artistMap[song.artistId!] = ArtistModel(
            id: song.artistId!,
            name: song.artist,
            imagePath: artwork,
            songIds: [],
            trackCount: 0,
            albumIds: [],
          );
        }
        final artist = artistMap[song.artistId!]!;
        
        final albumIds = List<String>.from(artist.albumIds);
        if (song.albumId != null && !albumIds.contains(song.albumId!)) {
          albumIds.add(song.albumId!);
        }

        artistMap[song.artistId!] = artist.copyWith(
          songIds: [...artist.songIds, song.id],
          trackCount: artist.trackCount + 1,
          albumIds: albumIds,
          albumCount: albumIds.length,
        );
      }
    }
    return artistMap.values.toList();
  }

  Future<List<PlaylistModel>> getPlaylistsFromCache() async {
    return _playlistBox.values.toList();
  }

  // --- MÉTHODES DE SCAN (Appel système + Mise à jour cache) ---

  Future<List<SongModel>> scanAndCacheSongs() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        AppLogger.w('Permissions refusées');
        return [];
      }

      await _initArtworkCache();

      final minDurationSeconds = await _ref.read(minSongDurationProvider.future);

      final deviceSongs = await _audioQuery.querySongs(
        sortType: aq.SongSortType.TITLE,
        orderType: aq.OrderType.ASC_OR_SMALLER,
        uriType: aq.UriType.EXTERNAL,
        ignoreCase: true,
      );

      final cachedSongs = _songBox.values.toList();
      final cachedSongsMap = {for (var s in cachedSongs) s.id: s};

      final mergedSongs = <SongModel>[];
      for (final deviceSong in deviceSongs) {
        if (deviceSong.duration != null && deviceSong.duration! < (minDurationSeconds * 1000)) {
          continue;
        }

        final cachedSong = cachedSongsMap[deviceSong.id.toString()];

        if (cachedSong != null) {
          mergedSongs.add(cachedSong.copyWith(
            title: deviceSong.title,
            artist: deviceSong.artist ?? 'Artiste inconnu',
            album: deviceSong.album ?? 'Album inconnu',
            path: deviceSong.data,
            duration: deviceSong.duration ?? 0,
            albumArtPath: await _getAndCacheArtwork(
                deviceSong.id, 'song_${deviceSong.id}'),
            // Mettre à jour dateAdded si disponible
            dateAdded: deviceSong.dateAdded,
          ));
        } else {
          mergedSongs.add(await _mapToSongModelWithArtwork(deviceSong));
        }
      }

      await _songBox.clear();
      await _songBox.putAll({for (var s in mergedSongs) s.id: s});

      return mergedSongs;
    } catch (e) {
      AppLogger.e('Erreur lors du scan', error: e);
      return getSongsFromCache();
    }
  }

  // --- MÉTHODES UTILITAIRES ---

  Future<void> updateSong(SongModel song) async {
    await _songBox.put(song.id, song);
  }

  Future<void> createPlaylist(PlaylistModel playlist) async {
    await _playlistBox.put(playlist.id, playlist);
  }

  Future<void> addSongToPlaylist(String songId, String playlistId) async {
    final playlist = _playlistBox.get(playlistId);
    if (playlist != null) {
      if (!playlist.songIds.contains(songId)) {
        final updatedPlaylist =
            playlist.copyWith(songIds: [...playlist.songIds, songId]);
        await _playlistBox.put(playlistId, updatedPlaylist);
      }
    }
  }

  Future<void> removeSongFromPlaylist(String songId, String playlistId) async {
    final playlist = _playlistBox.get(playlistId);
    if (playlist != null) {
      final updatedSongIds =
          playlist.songIds.where((id) => id != songId).toList();
      final updatedPlaylist = playlist.copyWith(songIds: updatedSongIds);
      await _playlistBox.put(playlistId, updatedPlaylist);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistBox.delete(playlistId);
  }

  /// Récupère les paroles : cache → fichier .lrc → métadonnées (tags). Les résultats sont mis en cache.
  /// Lecture du cache sécurisée : en cas d'erreur ou donnée invalide, on tente toujours .lrc et tags.
  Future<String?> getLyrics(String songId) async {
    try {
      // 0) Cache (ne jamais bloquer .lrc/tags)
      String? cached;
      try {
        final raw = _lyricsCacheBox.get(songId);
        if (raw is String && raw.trim().isNotEmpty) cached = raw;
      } catch (_) {}
      if (cached != null) return cached;

      final song = _songBox.get(songId);
      if (song == null) return null;

      String? result;

      // 1) Fichier .lrc à côté du fichier audio
      try {
        final dir = path.dirname(song.path);
        final baseName = path.basenameWithoutExtension(song.path);
        final lrcPath = path.join(dir, '$baseName.lrc');
        final lrcFile = File(lrcPath);
        if (await lrcFile.exists()) {
          final content = await lrcFile.readAsString();
          if (content.trim().isNotEmpty) result = content;
        }
      } catch (_) {}

      // 2) Paroles dans les métadonnées (tags)
      if (result == null) {
        try {
          final tags = await _tagger.readTags(path: song.path);
          result = tags?.lyrics;
        } catch (_) {}
      }

      if (result != null && result.trim().isNotEmpty) {
        await saveLyricsToCache(songId, result);
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Enregistre les paroles en cache (clé = songId). N'enregistre pas les paroles vides.
  Future<void> saveLyricsToCache(String songId, String lyrics) async {
    if (lyrics.trim().isEmpty) return;
    try {
      await _lyricsCacheBox.put(songId, lyrics);
    } catch (e) {
      AppLogger.w('saveLyricsToCache failed for $songId', error: e);
    }
  }

  static const String _userAgent = 'LKMPlayer/1.0';
  static const Duration _timeout = Duration(seconds: 12);

  /// Récupère les paroles en ligne : LRCLib (direct + search) puis Lyrics.ovh.
  /// Préfère les paroles synchronisées (LRC), sinon le texte brut.
  /// Un retry est fait en cas de connexion fermée / handshake (réseau instable).
  Future<String?> getLyricsFromWeb(String artist, String title, {int? durationMs, String? album}) async {
    var lyrics = await _getWithRetry(() => _getLyricsFromLrclib(artist, title, durationMs: durationMs, album: album));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    lyrics = await _getWithRetry(() => _getLyricsFromLrclibSearch(artist, title));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    lyrics = await _getWithRetry(() => _getLyricsFromLyricsOvh(artist, title));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    return null;
  }

  Future<String?> _getWithRetry(Future<String?> Function() fn) async {
    var result = await fn();
    if (result != null && result.trim().isNotEmpty) return result;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return fn();
  }

  Future<String?> _getLyricsFromLrclib(String artist, String title, {int? durationMs, String? album}) async {
    try {
      final durationSec = durationMs != null ? (durationMs / 1000).round() : null;
      final query = <String, String>{
        'artist_name': artist,
        'track_name': title,
        if (album != null && album.isNotEmpty) 'album_name': album,
        if (durationSec != null && durationSec > 0) 'duration': durationSec.toString(),
      };
      final uri = Uri.https('lrclib.net', 'api/get', query);
      final response = await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout, onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final synced = json['syncedLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) return synced.trim();
      final plain = json['plainLyrics'] as String?;
      if (plain != null && plain.trim().isNotEmpty) return plain.trim();
      return null;
    } catch (e) {
      AppLogger.w('_getLyricsFromLrclib failed for $artist / $title', error: e);
      return null;
    }
  }

  Future<String?> _getLyricsFromLrclibSearch(String artist, String title) async {
    try {
      final q = '$artist $title'.trim();
      if (q.isEmpty) return null;
      final uri = Uri.https('lrclib.net', 'api/search', {'q': q, 'limit': '5'});
      final response = await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout, onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>?;
      if (first == null) return null;
      final id = first['id'];
      if (id == null) return null;
      final byIdUri = Uri.https('lrclib.net', 'api/get', {'id': id.toString()});
      final byIdResponse = await http.get(byIdUri, headers: {'User-Agent': _userAgent}).timeout(_timeout, onTimeout: () => http.Response('', 408));
      if (byIdResponse.statusCode != 200) return null;
      final json = jsonDecode(byIdResponse.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final synced = json['syncedLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) return synced.trim();
      final plain = json['plainLyrics'] as String?;
      if (plain != null && plain.trim().isNotEmpty) return plain.trim();
      return null;
    } catch (e) {
      AppLogger.w('_getLyricsFromLrclibSearch failed for $artist / $title', error: e);
      return null;
    }
  }

  Future<String?> _getLyricsFromLyricsOvh(String artist, String title) async {
    try {
      final path = 'v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}';
      final uri = Uri.https('api.lyrics.ovh', path);
      final response = await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout, onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final lyrics = json['lyrics'] as String?;
      return lyrics?.trim();
    } catch (e) {
      AppLogger.w('_getLyricsFromLyricsOvh failed for $artist / $title', error: e);
      return null;
    }
  }

  Future<List<AlbumModel>> getAllAlbums() async {
     return getAlbumsFromCache();
  }

  Future<List<ArtistModel>> getAllArtists() async {
    return getArtistsFromCache();
  }

  Future<List<SongModel>> getSongsByAlbum(String albumId) async {
    final songs = await getSongsFromCache();
    return songs.where((s) => s.albumId == albumId).toList();
  }

  Future<List<SongModel>> getSongsByArtist(String artistId) async {
    final songs = await getSongsFromCache();
    return songs.where((s) => s.artistId == artistId).toList();
  }

  Future<List<SongModel>> searchSongs(String query) async {
    final allSongs = await getSongsFromCache();
    final lowerQuery = query.toLowerCase();
    return allSongs
        .where((song) =>
            song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            song.album.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<List<int>?> getSongArtwork(String songId) async {
    try {
      return await _audioQuery.queryArtwork(
        int.parse(songId),
        aq.ArtworkType.AUDIO,
        quality: 100,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getAndCacheArtwork(int songId, String cacheFileName) async {
    try {
      if (_artworkCacheDir == null) {
        await _initArtworkCache();
      }
      final cachedFile = File(
        path.join(_artworkCacheDir!.path, '$cacheFileName.jpg'),
      );
      if (await cachedFile.exists()) {
        return cachedFile.path;
      }
      final artworkBytes = await _audioQuery.queryArtwork(
        songId,
        aq.ArtworkType.AUDIO,
        quality: 100,
        size: 500,
      );
      if (artworkBytes != null && artworkBytes.isNotEmpty) {
        await cachedFile.writeAsBytes(artworkBytes);
        return cachedFile.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SongModel> _mapToSongModelWithArtwork(aq.SongModel song) async {
    final artworkPath = await _getAndCacheArtwork(
      song.id,
      'song_${song.id}',
    );
    int? year;
    final dynamic yearFromMap = song.getMap['year'];
    if (yearFromMap != null) {
      year = int.tryParse(yearFromMap.toString());
    }
    return SongModel(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Artiste inconnu',
      album: song.album ?? 'Album inconnu',
      path: song.data,
      duration: song.duration ?? 0,
      albumArtPath: artworkPath,
      genre: song.genre,
      year: year,
      trackNumber: song.track,
      albumId: song.albumId?.toString(),
      artistId: song.artistId?.toString(),
      dateAdded: song.dateAdded, // Récupérer la date d'ajout
    );
  }

  /// Nettoyer le cache des artworks
  Future<void> clearArtworkCache() async {
    try {
      if (_artworkCacheDir == null) {
        await _initArtworkCache();
      }
      if (await _artworkCacheDir!.exists()) {
        await _artworkCacheDir!.delete(recursive: true);
        await _artworkCacheDir!.create(recursive: true);
      }
    } catch (e) {
      AppLogger.e('Erreur lors du nettoyage du cache', error: e);
    }
  }
}
