import 'dart:io';

import 'package:archive/archive.dart';
import 'package:audiotags/audiotags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../music/data/models/song_model.dart';
import '../../../music/presentation/providers/music_provider.dart';
import '../../data/models/deezer_search_result.dart';
import '../../data/telegramusic_api_client.dart';

final downloadApiClientProvider = Provider<TelegramusicApiClient?>((ref) {
  final baseUrl = ref.watch(downloadApiBaseUrlProvider).valueOrNull ?? '';
  if (baseUrl.isEmpty) return null;
  return TelegramusicApiClient(baseUrl: baseUrl);
});

/// Chemin du dossier où sont enregistrées les pistes téléchargées (Téléchargements/Musio).
Future<String> getDownloadDirectoryPath() async {
  final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  return path.join(dir.path, 'Musio');
}

/// Provider exposant le chemin du dossier de téléchargement (pour l’affichage dans Paramètres).
final downloadDirectoryPathProvider = FutureProvider<String>((ref) => getDownloadDirectoryPath());

/// État de la recherche en ligne (Deezer).
class OnlineSearchState {
  const OnlineSearchState({
    this.results = const [],
    this.albumResults = const [],
    this.isLoading = false,
    this.error,
  });

  final List<DeezerSearchResult> results;
  final List<DeezerSearchResult> albumResults;
  final bool isLoading;
  final String? error;

  OnlineSearchState copyWith({
    List<DeezerSearchResult>? results,
    List<DeezerSearchResult>? albumResults,
    bool? isLoading,
    String? error,
  }) {
    return OnlineSearchState(
      results: results ?? this.results,
      albumResults: albumResults ?? this.albumResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final onlineSearchStateProvider =
    StateNotifierProvider<OnlineSearchNotifier, OnlineSearchState>((ref) {
  return OnlineSearchNotifier(ref);
});

class OnlineSearchNotifier extends StateNotifier<OnlineSearchState> {
  OnlineSearchNotifier(this._ref) : super(const OnlineSearchState());

  final Ref _ref;

  /// Normalise la requête (trim, espaces multiples → un seul) pour limiter les erreurs / 502.
  static String _normalizeQuery(String q) {
    return q.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Requête envoyée à l'API : normalisée + espace en fin pour éviter 502 côté serveur.
  static String _queryForApi(String normalized) {
    return normalized.isEmpty ? '' : '$normalized ';
  }

  Future<void> search(String query) async {
    final normalized = _normalizeQuery(query);
    if (normalized.isEmpty) {
      state = state.copyWith(results: [], albumResults: [], error: null);
      return;
    }
    final client = _ref.read(downloadApiClientProvider);
    if (client == null || !client.isConfigured) {
      state = state.copyWith(
        results: [],
        albumResults: [],
        isLoading: false,
        error: 'Configurez le serveur de téléchargement dans Paramètres',
      );
      return;
    }
    final queryForApi = _queryForApi(normalized);
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await client.searchResults(queryForApi, type: 'track');
      final albumResults = await client.searchResults(queryForApi, type: 'album');
      state = state.copyWith(
        results: results,
        albumResults: albumResults,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        results: [],
        albumResults: [],
        isLoading: false,
        error: msg,
      );
    }
  }

  void clear() {
    state = const OnlineSearchState();
  }
}

/// ID du morceau en cours de téléchargement (pour afficher un loader).
final downloadingTrackIdProvider = StateProvider<String?>((ref) => null);

/// ID de l'album en cours de téléchargement.
final downloadingAlbumIdProvider = StateProvider<String?>((ref) => null);

/// Progression du téléchargement en cours : 0.0 à 1.0, ou null si pas de téléchargement.
final downloadProgressProvider = StateProvider<double?>((ref) => null);

/// Label affiché pendant le téléchargement (ex: titre du morceau ou de l'album).
final downloadingLabelProvider = StateProvider<String?>((ref) => null);

/// Résultat d'un téléchargement (succès avec chemin ou échec).
class DownloadResult {
  const DownloadResult({
    this.song,
    this.filePath,
    this.error,
    this.trackCount,
  });

  final SongModel? song;
  final String? filePath;
  final String? error;
  /// Nombre de pistes (pour un album).
  final int? trackCount;

  bool get isSuccess => filePath != null && error == null;
}

/// Télécharge un morceau via l'API, l'enregistre sur l'appareil et l'ajoute à la bibliothèque.
Future<DownloadResult> downloadTrackAndAddToLibrary(
  WidgetRef ref,
  DeezerSearchResult track,
) async {
  final client = ref.read(downloadApiClientProvider);
  if (client == null || !client.isConfigured) {
    return const DownloadResult(error: 'API non configurée');
  }

  ref.read(downloadingTrackIdProvider.notifier).state = track.id;
  ref.read(downloadProgressProvider.notifier).state = 0.0;
  ref.read(downloadingLabelProvider.notifier).state = track.title;

  try {
    final bytes = await client.downloadTrack(
      track.id,
      onProgress: (received, total) {
        if (total != null && total > 0) {
          ref.read(downloadProgressProvider.notifier).state = received / total;
        }
      },
    );
    if (bytes.isEmpty) {
      return const DownloadResult(error: 'Fichier vide');
    }

    ref.read(downloadProgressProvider.notifier).state = 1.0;

    final downloadDirPath = await getDownloadDirectoryPath();
    final downloadDir = Directory(downloadDirPath);
    if (!await downloadDir.exists()) await downloadDir.create(recursive: true);

    final safeTitle = _sanitizeFileName(track.title);
    final safeArtist = _sanitizeFileName(track.artist);
    final fileName = '$safeArtist - $safeTitle.mp3';
    final filePath = path.join(downloadDir.path, fileName);
    final file = File(filePath);

    await file.writeAsBytes(bytes);

    // Extraire métadonnées et pochette du fichier
    String title = track.title;
    String artist = track.artist;
    String album = track.album ?? '';
    int durationMs = 0;
    int? year;
    int? trackNumber;
    String? albumArtPath;

    try {
      final tag = await AudioTags.read(file.path);
      title = tag?.title ?? title;
      artist = tag?.trackArtist ?? artist;
      album = tag?.album ?? album;
      durationMs = (tag?.duration ?? 0) * 1000;
      year = tag?.year;
      trackNumber = tag?.trackNumber;
      if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final artDir = Directory(path.join(appDir.path, 'album_artworks'));
        if (!await artDir.exists()) await artDir.create(recursive: true);
        final artPath = path.join(artDir.path, 'deezer_${track.id}.jpg');
        await File(artPath).writeAsBytes(tag.pictures!.first.bytes);
        albumArtPath = artPath;
      }
    } catch (_) {
      // Garder les valeurs par défaut si la lecture échoue
    }

    final songId = 'deezer_${track.id}';
    final song = SongModel(
      id: songId,
      title: title,
      artist: artist,
      album: album,
      path: filePath,
      duration: durationMs,
      albumArtPath: albumArtPath,
      year: year,
      trackNumber: trackNumber,
      albumId: 'deezer_track_${track.id}',
      artistId: _deezerArtistId(track.artist),
      dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final repository = ref.read(musicRepositoryProvider);
    await repository.addDownloadedSong(song);

    await ref.read(musicProvider.notifier).loadFromCache();

    return DownloadResult(song: song, filePath: filePath);
  } catch (e) {
    return DownloadResult(error: e.toString().replaceFirst('Exception: ', ''));
  } finally {
    ref.read(downloadingTrackIdProvider.notifier).state = null;
    ref.read(downloadProgressProvider.notifier).state = null;
    ref.read(downloadingLabelProvider.notifier).state = null;
  }
}

/// Télécharge un album (ZIP) via l'API, extrait les pistes et les ajoute à la bibliothèque.
Future<DownloadResult> downloadAlbumAndAddToLibrary(
  WidgetRef ref,
  DeezerSearchResult album,
) async {
  final client = ref.read(downloadApiClientProvider);
  if (client == null || !client.isConfigured) {
    return const DownloadResult(error: 'API non configurée');
  }

  ref.read(downloadingAlbumIdProvider.notifier).state = album.id;
  ref.read(downloadProgressProvider.notifier).state = 0.0;
  ref.read(downloadingLabelProvider.notifier).state = album.displayTitle;

  try {
    final bytes = await client.downloadAlbum(
      album.id,
      onProgress: (received, total) {
        if (total != null && total > 0) {
          ref.read(downloadProgressProvider.notifier).state = received / total;
        }
      },
    );
    if (bytes.isEmpty) {
      return const DownloadResult(error: 'Archive vide');
    }

    ref.read(downloadProgressProvider.notifier).state = 1.0;

    final archive = ZipDecoder().decodeBytes(bytes);
    final downloadDirPath = await getDownloadDirectoryPath();
    final albumFolderName = '${_sanitizeFileName(album.artist)} - ${_sanitizeFileName(album.displayTitle)}';
    final albumDirPath = path.join(downloadDirPath, albumFolderName);
    final albumDir = Directory(albumDirPath);
    if (!await albumDir.exists()) await albumDir.create(recursive: true);

    final appDir = await getApplicationDocumentsDirectory();
    final artDir = Directory(path.join(appDir.path, 'album_artworks'));
    if (!await artDir.exists()) await artDir.create(recursive: true);

    final repository = ref.read(musicRepositoryProvider);
    int index = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      final name = path.basename(file.name);
      if (!_isAudioFileName(name)) continue;

      final outPath = path.join(albumDirPath, name);
      await File(outPath).writeAsBytes(file.content as List<int>);
      final outFile = File(outPath);

      String title = name;
      String artist = album.artist;
      String albumName = album.displayTitle;
      int durationMs = 0;
      int? year;
      int? trackNumber;
      String? albumArtPath;

      try {
        final tag = await AudioTags.read(outFile.path);
        title = tag?.title ?? title;
        artist = tag?.trackArtist ?? artist;
        albumName = tag?.album ?? albumName;
        durationMs = (tag?.duration ?? 0) * 1000;
        year = tag?.year;
        trackNumber = tag?.trackNumber;
        if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
          final artPath = path.join(artDir.path, 'deezer_album_${album.id}_$index.jpg');
          await File(artPath).writeAsBytes(tag.pictures!.first.bytes);
          albumArtPath = artPath;
        }
      } catch (_) {}

      final songId = 'deezer_album_${album.id}_$index';
      final song = SongModel(
        id: songId,
        title: title,
        artist: artist,
        album: albumName,
        path: outPath,
        duration: durationMs,
        albumArtPath: albumArtPath,
        year: year,
        trackNumber: trackNumber,
        albumId: album.id,
        artistId: _deezerArtistId(album.artist),
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await repository.addDownloadedSong(song);
      index++;
    }

    await ref.read(musicProvider.notifier).loadFromCache();

    return DownloadResult(
      filePath: albumDirPath,
      trackCount: index,
    );
  } catch (e) {
    return DownloadResult(error: e.toString().replaceFirst('Exception: ', ''));
  } finally {
    ref.read(downloadingAlbumIdProvider.notifier).state = null;
    ref.read(downloadProgressProvider.notifier).state = null;
    ref.read(downloadingLabelProvider.notifier).state = null;
  }
}

bool _isAudioFileName(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.mp3') || lower.endsWith('.flac') || lower.endsWith('.m4a');
}

String _sanitizeFileName(String s) {
  return s.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
}

/// Identifiant stable pour grouper les artistes des morceaux téléchargés (Deezer).
String _deezerArtistId(String artist) {
  final safe = artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  return 'deezer_artist_${safe.isEmpty ? 'inconnu' : safe}';
}
