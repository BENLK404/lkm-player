import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart' as aq;
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
  late Box<SongModel> _songBox;
  late Box<PlaylistModel> _playlistBox;
  late Box _lyricsCacheBox;

  Directory? _artworkCacheDir;
  final Ref _ref;

  // ─── Patterns par app ────────────────────────────────────────────────────────
  static const _whatsappPatterns = ['whatsapp', 'com.whatsapp'];
  static const _telegramPatterns = ['telegram', 'org.telegram'];
  static const _signalPatterns = ['signal', 'org.thoughtcrime.securesms'];
  static const _viberPatterns = ['viber', 'com.viber.voip'];
  static const _discordPatterns = ['discord', 'com.discord'];
  static const _otherPatterns = [
    'com.facebook.orca',
    'com.facebook.mlite',
    'skype',
    'com.skype',
    'line',
    'jp.naver.line',
    'wechat',
    'com.tencent.mm',
    'com.snapchat.android',
    'slack',
    'com.slack',
  ];

  bool _matchesPatterns(String filePath, List<String> patterns) {
    final lower = filePath.toLowerCase();
    return patterns.any((p) => lower.contains(p));
  }

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
      appLogger.e('Erreur lors de la demande de permissions', error: e);
      return false;
    } catch (e) {
      appLogger.e('Erreur inattendue lors de la demande de permissions',
          error: e);
      return false;
    }
  }

  // --- MÉTHODES DE CACHE (Lecture seule, pas de scan) ---

  Future<List<SongModel>> getSongsFromCache() async {
    return _songBox.values.toList();
  }

  /// Clé d'album effective : albumId si présent, sinon clé générée à partir de (album, artist)
  /// pour que les morceaux sans albumId (ex. anciens téléchargements) soient quand même regroupés.
  static String? effectiveAlbumKey(SongModel s) {
    if (s.albumId != null && s.albumId!.isNotEmpty) return s.albumId;
    final a = s.album.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final ar = s.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (a.isEmpty && ar.isEmpty) return null;
    return 'gen_${a.isEmpty ? 'unknown' : a}_${ar.isEmpty ? 'unknown' : ar}';
  }

  /// Clé artiste effective : artistId si présent, sinon clé générée à partir du nom d'artiste.
  static String? effectiveArtistKey(SongModel s) {
    if (s.artistId != null && s.artistId!.isNotEmpty) return s.artistId;
    final ar = s.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (ar.isEmpty) return null;
    return 'gen_artist_$ar';
  }

  Future<List<AlbumModel>> getAlbumsFromCache() async {
    final songs = _songBox.values.toList();
    final albumMap = <String, AlbumModel>{};

    for (var song in songs) {
      final key = effectiveAlbumKey(song);
      if (key == null) continue;
      if (!albumMap.containsKey(key)) {
        albumMap[key] = AlbumModel(
          id: key,
          name: song.album,
          artist: song.artist,
          albumArtPath: song.albumArtPath,
          year: song.year,
          songIds: [],
          trackCount: 0,
        );
      }
      final album = albumMap[key]!;
      albumMap[key] = album.copyWith(
        songIds: [...album.songIds, song.id],
        trackCount: album.trackCount + 1,
      );
    }
    return albumMap.values.toList();
  }

  Future<List<ArtistModel>> getArtistsFromCache() async {
    final songs = _songBox.values.toList();
    final artistMap = <String, ArtistModel>{};

    for (var song in songs) {
      final key = effectiveArtistKey(song);
      if (key == null) continue;
      if (!artistMap.containsKey(key)) {
        final artwork = songs
            .firstWhere(
              (s) => effectiveArtistKey(s) == key && s.albumArtPath != null,
              orElse: () => song,
            )
            .albumArtPath;

        artistMap[key] = ArtistModel(
          id: key,
          name: song.artist,
          imagePath: artwork,
          songIds: [],
          trackCount: 0,
          albumIds: [],
        );
      }
      final artist = artistMap[key]!;

      final albumIds = List<String>.from(artist.albumIds);
      final albumKey = effectiveAlbumKey(song);
      if (albumKey != null && !albumIds.contains(albumKey)) {
        albumIds.add(albumKey);
      }

      artistMap[key] = artist.copyWith(
        songIds: [...artist.songIds, song.id],
        trackCount: artist.trackCount + 1,
        albumIds: albumIds,
        albumCount: albumIds.length,
      );
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
        appLogger.w('Permissions refusées');
        return [];
      }

      await _initArtworkCache();

      final minDurationSeconds =
          await _ref.read(minSongDurationProvider.future);

      // Lire les préférences de filtrage par app
      final excludeGlobal =
          await _ref.read(excludeMessagingAppsProvider.future);
      final excludeWhatsApp = await _ref.read(excludeWhatsAppProvider.future);
      final excludeTelegram = await _ref.read(excludeTelegramProvider.future);
      final excludeSignal = await _ref.read(excludeSignalProvider.future);
      final excludeViber = await _ref.read(excludeViberProvider.future);
      final excludeDiscord = await _ref.read(excludeDiscordProvider.future);
      final excludeOther =
          await _ref.read(excludeOtherMessagingProvider.future);

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
        // Filtre durée minimale
        if (deviceSong.duration != null &&
            deviceSong.duration! < (minDurationSeconds * 1000)) {
          continue;
        }

        // Filtre messagerie granulaire
        if (excludeGlobal) {
          final p = deviceSong.data;
          if (excludeWhatsApp && _matchesPatterns(p, _whatsappPatterns)) {
            appLogger.d('Exclu (WhatsApp) : $p');
            continue;
          }
          if (excludeTelegram && _matchesPatterns(p, _telegramPatterns)) {
            appLogger.d('Exclu (Telegram) : $p');
            continue;
          }
          if (excludeSignal && _matchesPatterns(p, _signalPatterns)) {
            appLogger.d('Exclu (Signal) : $p');
            continue;
          }
          if (excludeViber && _matchesPatterns(p, _viberPatterns)) {
            appLogger.d('Exclu (Viber) : $p');
            continue;
          }
          if (excludeDiscord && _matchesPatterns(p, _discordPatterns)) {
            appLogger.d('Exclu (Discord) : $p');
            continue;
          }
          if (excludeOther && _matchesPatterns(p, _otherPatterns)) {
            appLogger.d('Exclu (Autre messagerie) : $p');
            continue;
          }
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
            dateAdded: deviceSong.dateAdded,
          ));
        } else {
          mergedSongs.add(await _mapToSongModelWithArtwork(deviceSong));
        }
      }

      // Conserver les pistes téléchargées (Deezer) dont le fichier existe encore
      final mergedPaths = {for (var s in mergedSongs) s.path};
      for (final song in cachedSongs) {
        if (song.id.startsWith('deezer_') && !mergedPaths.contains(song.path)) {
          final file = File(song.path);
          if (await file.exists()) {
            mergedSongs.add(song);
            mergedPaths.add(song.path);
          }
        }
      }

      await _songBox.clear();
      await _songBox.putAll({for (var s in mergedSongs) s.id: s});

      return mergedSongs;
    } catch (e) {
      appLogger.e('Erreur lors du scan', error: e);
      return getSongsFromCache();
    }
  }

  // --- MÉTHODES UTILITAIRES ---

  Future<void> updateSong(SongModel song) async {
    await _songBox.put(song.id, song);
  }

  /// Ajoute une chanson téléchargée (ex. via API) à la bibliothèque sans scan.
  Future<void> addDownloadedSong(SongModel song) async {
    await _songBox.put(song.id, song);
  }

  /// Supprime un morceau de la bibliothèque et optionnellement le fichier du disque.
  Future<void> removeSong(String songId, {bool deleteFile = true}) async {
    final song = _songBox.get(songId);
    if (song == null) return;
    await _songBox.delete(songId);
    if (deleteFile) {
      try {
        final file = File(song.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Supprime un album de la bibliothèque (toutes les pistes) et optionnellement les fichiers.
  Future<void> removeAlbum(String albumId, {bool deleteFiles = true}) async {
    final songs =
        _songBox.values.where((s) => effectiveAlbumKey(s) == albumId).toList();
    for (final song in songs) {
      await _songBox.delete(song.id);
      if (deleteFiles) {
        try {
          final file = File(song.path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
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

  /// Récupère les paroles : cache → fichier .lrc. Les résultats sont mis en cache.
  /// (Paroles en ligne gérées par lyrics_provider après appel à getLyrics.)
  /// [songOverride] : si fourni, utilisé pour chercher le .lrc (piste récemment ajoutée ou en queue non encore en cache).
  Future<String?> getLyrics(String songId, {SongModel? songOverride}) async {
    try {
      // 0) Cache
      String? cached;
      try {
        final raw = _lyricsCacheBox.get(songId);
        if (raw is String && raw.trim().isNotEmpty) cached = raw;
      } catch (_) {}
      if (cached != null) return cached;

      final song = songOverride ?? _songBox.get(songId);
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
      appLogger.w('saveLyricsToCache failed for $songId', error: e);
    }
  }

  static const String _userAgent = 'LKMPlayer/1.0';
  static const Duration _timeout = Duration(seconds: 25);

  /// Récupère les paroles en ligne : LRCLib (direct + search) puis Lyrics.ovh.
  /// Préfère les paroles synchronisées (LRC), sinon le texte brut.
  /// Un retry est fait en cas de connexion fermée / handshake (réseau instable).
  Future<String?> getLyricsFromWeb(String artist, String title,
      {int? durationMs, String? album}) async {
    var lyrics = await _getWithRetry(() => _getLyricsFromLrclib(artist, title,
        durationMs: durationMs, album: album));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    lyrics =
        await _getWithRetry(() => _getLyricsFromLrclibSearch(artist, title));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    lyrics = await _getWithRetry(() => _getLyricsFromLyricsOvh(artist, title));
    if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();

    return null;
  }

  Future<String?> _getWithRetry(Future<String?> Function() fn) async {
    final result = await fn();
    if (result != null && result.trim().isNotEmpty) return result;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return fn();
  }

  Future<String?> _getLyricsFromLrclib(String artist, String title,
      {int? durationMs, String? album}) async {
    try {
      final durationSec =
          durationMs != null ? (durationMs / 1000).round() : null;
      final query = <String, String>{
        'artist_name': artist,
        'track_name': title,
        if (album != null && album.isNotEmpty) 'album_name': album,
        if (durationSec != null && durationSec > 0)
          'duration': durationSec.toString(),
      };
      final uri = Uri.https('lrclib.net', 'api/get', query);
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout,
              onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final synced = json['syncedLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) return synced.trim();
      final plain = json['plainLyrics'] as String?;
      if (plain != null && plain.trim().isNotEmpty) return plain.trim();
      return null;
    } catch (e) {
      appLogger.w('_getLyricsFromLrclib failed for $artist / $title', error: e);
      return null;
    }
  }

  Future<String?> _getLyricsFromLrclibSearch(
      String artist, String title) async {
    try {
      final q = '$artist $title'.trim();
      if (q.isEmpty) return null;
      final uri = Uri.https('lrclib.net', 'api/search', {'q': q, 'limit': '5'});
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout,
              onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>?;
      if (first == null) return null;
      final id = first['id'];
      if (id == null) return null;
      final byIdUri = Uri.https('lrclib.net', 'api/get', {'id': id.toString()});
      final byIdResponse = await http
          .get(byIdUri, headers: {'User-Agent': _userAgent}).timeout(_timeout,
              onTimeout: () => http.Response('', 408));
      if (byIdResponse.statusCode != 200) return null;
      final json = jsonDecode(byIdResponse.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final synced = json['syncedLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) return synced.trim();
      final plain = json['plainLyrics'] as String?;
      if (plain != null && plain.trim().isNotEmpty) return plain.trim();
      return null;
    } catch (e) {
      appLogger.w('_getLyricsFromLrclibSearch failed for $artist / $title',
          error: e);
      return null;
    }
  }

  Future<String?> _getLyricsFromLyricsOvh(String artist, String title) async {
    try {
      final path =
          'v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}';
      final uri = Uri.https('api.lyrics.ovh', path);
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout,
              onTimeout: () => http.Response('', 408));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return null;
      final lyrics = json['lyrics'] as String?;
      return lyrics?.trim();
    } catch (e) {
      appLogger.w('_getLyricsFromLyricsOvh failed for $artist / $title',
          error: e);
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
    return songs.where((s) => effectiveAlbumKey(s) == albumId).toList();
  }

  Future<List<SongModel>> getSongsByArtist(String artistId) async {
    final songs = await getSongsFromCache();
    return songs.where((s) => effectiveArtistKey(s) == artistId).toList();
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
    // Construire l'URI MediaStore directement — pas de queryArtwork
    final albumArtUri = song.albumId != null
        ? 'content://media/external/audio/albumart/${song.albumId}'
        : null;

    return SongModel(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Artiste inconnu',
      album: song.album ?? '',
      path: song.data,
      duration: song.duration ?? 0,
      albumArtPath: albumArtUri, // URI content:// au lieu d'un path fichier
      genre: song.genre,
      year: song.dateModified,
      trackNumber: song.track,
      albumId: song.albumId?.toString(),
      artistId: song.artistId?.toString(),
      dateAdded: song.dateAdded,
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
      appLogger.e('Erreur lors du nettoyage du cache', error: e);
    }
  }
}
