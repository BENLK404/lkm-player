import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'download_cancel_token.dart';
import 'models/deezer_search_result.dart';

/// Client HTTP pour l'API Telegramusic (recherche + téléchargement).
class TelegramusicApiClient {
  TelegramusicApiClient({required String baseUrl})
      : baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  bool get isConfigured => baseUrl.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final u = '$baseUrl$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(u).replace(queryParameters: queryParams);
    }
    return Uri.parse(u);
  }

  /// GET /api/search?q=...&type=track|album
  Future<Map<String, dynamic>> search(String query, {String type = 'track'}) async {
    if (!isConfigured) throw Exception('API non configurée');
    try {
      final response = await http
          .get(
            _uri('/api/search', {'q': query, 'type': type}),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Recherche échouée: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      return json ?? {};
    } on SocketException {
      throw Exception('Serveur injoignable. Vérifiez l\'URL ($baseUrl), que l\'API est démarrée et que le téléphone est sur le même Wi‑Fi.');
    } on TimeoutException {
      throw Exception('Délai dépassé. Le serveur $baseUrl ne répond pas.');
    }
  }

  /// Liste des résultats de recherche (tracks ou albums).
  Future<List<DeezerSearchResult>> searchResults(String query, {String type = 'track'}) async {
    final data = await search(query, type: type);
    final results = data['results'] as List<dynamic>?;
    if (results == null) return [];
    return results
        .map((e) => DeezerSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/download/track/{id} → bytes du fichier audio.
  /// [onProgress] appelé avec (bytes reçus, total ou null si inconnu).
  Future<List<int>> downloadTrack(
    String trackId, {
    void Function(int received, int? total)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    if (!isConfigured) throw Exception('API non configurée');
    final request = http.Request('GET', _uri('/api/download/track/$trackId'));
    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(const Duration(minutes: 2));
      if (streamed.statusCode != 200) {
        throw Exception('Téléchargement échoué: ${streamed.statusCode}');
      }
      final total = streamed.contentLength;
      int received = 0;
      final chunks = <int>[];
      await for (final chunk in streamed.stream) {
        if (cancelToken?.isCancelled == true) {
          throw DownloadCancelledException(cancelToken!.reason ?? DownloadCancelReason.cancel);
        }
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total != null && total > 0 ? total : null);
      }
      return chunks;
    } finally {
      client.close();
    }
  }

  /// GET /api/track/{id}/cover → bytes de la pochette JPEG.
  Future<List<int>?> getTrackCover(String trackId) async {
    if (!isConfigured) return null;
    try {
      final response = await http
          .get(_uri('/api/track/$trackId/cover'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  /// URL de la pochette (pour Image.network).
  String trackCoverUrl(String trackId) => '$baseUrl/api/track/$trackId/cover';

  /// GET /api/download/album/{id} → bytes du ZIP.
  Future<List<int>> downloadAlbum(
    String albumId, {
    void Function(int received, int? total)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    if (!isConfigured) throw Exception('API non configurée');
    final request = http.Request('GET', _uri('/api/download/album/$albumId'));
    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(const Duration(minutes: 10));
      if (streamed.statusCode != 200) {
        throw Exception('Téléchargement album échoué: ${streamed.statusCode}');
      }
      final total = streamed.contentLength;
      int received = 0;
      final chunks = <int>[];
      await for (final chunk in streamed.stream) {
        if (cancelToken?.isCancelled == true) {
          throw DownloadCancelledException(cancelToken!.reason ?? DownloadCancelReason.cancel);
        }
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total != null && total > 0 ? total : null);
      }
      return chunks;
    } finally {
      client.close();
    }
  }

  /// URL pochette album (pour affichage).
  String albumCoverUrl(String albumId) => '$baseUrl/api/album/$albumId/cover';

  /// GET /api/album/{id}/tracks
  Future<List<DeezerSearchResult>> albumTracks(String albumId) async {
    if (!isConfigured) throw Exception('API non configurée');
    try {
      final response = await http
          .get(
            _uri('/api/album/$albumId/tracks'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Pistes album: ${response.statusCode}');
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      final raw = map?['tracks'] as List<dynamic>? ?? [];
      return raw
          .map((e) => DeezerSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw Exception('Serveur injoignable ($baseUrl).');
    } on TimeoutException {
      throw Exception('Délai dépassé.');
    }
  }
}
