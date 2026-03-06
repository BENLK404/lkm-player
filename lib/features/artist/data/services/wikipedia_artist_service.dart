import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/artist/data/models/artist_wikipedia_info.dart';

/// Récupère les informations d'un artiste depuis Wikipedia et les met en cache.
class WikipediaArtistService {
  WikipediaArtistService(this._cacheBox);

  final Box _cacheBox;
  static const _userAgent =
      'LKMPlayer/1.0 (https://github.com; contact@example.com)';
  static const _timeout = Duration(seconds: 20);
  static const _wikiLangs = ['en', 'fr']; // anglais puis français en secours

  /// Clé de cache normalisée à partir du nom d'artiste.
  String _cacheKey(String artistName) =>
      ArtistWikipediaInfo.cacheKeyFromArtistName(artistName);

  /// Retourne les infos depuis le cache si présentes.
  ArtistWikipediaInfo? getFromCache(String artistName) {
    try {
      final key = _cacheKey(artistName);
      final raw = _cacheBox.get(key);
      if (raw is! String || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>?;
      if (json == null) return null;
      return ArtistWikipediaInfo.fromJson(json);
    } catch (e) {
      AppLogger.w('Wikipedia cache read failed for $artistName', error: e);
      return null;
    }
  }

  /// Enregistre les infos en cache.
  Future<void> saveToCache(String artistName, ArtistWikipediaInfo info) async {
    try {
      final key = _cacheKey(artistName);
      await _cacheBox.put(key, jsonEncode(info.toJson()));
    } catch (e) {
      AppLogger.w('Wikipedia cache write failed for $artistName', error: e);
    }
  }

  /// Récupère les infos Wikipedia pour [artistName] : cache d'abord, puis API.
  Future<ArtistWikipediaInfo?> getArtistInfo(String artistName) async {
    final trimmed = artistName.trim();
    if (trimmed.isEmpty) return null;

    // 1) Cache
    final cached = getFromCache(trimmed);
    if (cached != null && cached.extract.isNotEmpty) return cached;

    // 2) API Wikipedia (essayer en anglais puis en français, avec 1 retry)
    for (final lang in _wikiLangs) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          if (attempt > 0) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          }
          final info = await _fetchFromWikipedia(trimmed, lang: lang);
          if (info != null && info.extract.isNotEmpty) {
            await saveToCache(trimmed, info);
            return info;
          }
          break; // pas d'erreur mais pas de résultat, passer à la langue suivante
        } catch (e) {
          AppLogger.w(
              'Wikipedia fetch failed for $artistName (lang=$lang, attempt=${attempt + 1})',
              error: e);
        }
      }
    }
    return null;
  }

  Future<ArtistWikipediaInfo?> _fetchFromWikipedia(String artistName,
      {required String lang}) async {
    final baseUrl = 'https://$lang.wikipedia.org/w/api.php';

    // 1) Recherche pour obtenir le pageid
    final searchUri = Uri.parse(baseUrl).replace(queryParameters: {
      'action': 'query',
      'list': 'search',
      'srsearch': artistName,
      'srlimit': '3',
      'format': 'json',
    });
    final searchResponse = await http
        .get(searchUri, headers: {'User-Agent': _userAgent})
        .timeout(_timeout, onTimeout: () => http.Response('', 408));

    if (searchResponse.statusCode != 200) return null;

    final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>?;
    final query = searchData?['query'] as Map<String, dynamic>?;
    final searchList = query?['search'] as List<dynamic>?;
    if (searchList == null || searchList.isEmpty) return null;

    final first = searchList.first as Map<String, dynamic>?;
    final pageId = first?['pageid'];
    final title = first?['title'] as String?;
    if (pageId == null || title == null) return null;

    // 2) Extraire l'intro de la page
    final extractUri = Uri.parse(baseUrl).replace(queryParameters: {
      'action': 'query',
      'pageids': pageId.toString(),
      'prop': 'extracts',
      'exintro': '1',
      'explaintext': '1',
      'exsentences': '8',
      'format': 'json',
    });
    final extractResponse = await http
        .get(extractUri, headers: {'User-Agent': _userAgent})
        .timeout(_timeout, onTimeout: () => http.Response('', 408));

    if (extractResponse.statusCode != 200) return null;

    final extractData =
        jsonDecode(extractResponse.body) as Map<String, dynamic>?;
    final pagesRaw = extractData?['query']?['pages'];
    if (pagesRaw is! Map) return null;
    final pages = pagesRaw as Map<String, dynamic>;

    // Trouver la première page qui contient un extrait (ignorer entrées "missing")
    Map<String, dynamic>? page;
    String? extract;
    for (final v in pages.values) {
      if (v is! Map<String, dynamic>) continue;
      final ex = v['extract'] as String?;
      if (ex != null && ex.trim().isNotEmpty) {
        page = v;
        extract = ex.trim();
        break;
      }
    }
    if (page == null || extract == null) return null;

    final pageTitle = page['title'] as String? ?? title;
    final pageUrl =
        'https://$lang.wikipedia.org/wiki/${Uri.encodeComponent(pageTitle.replaceAll(' ', '_'))}';

    return ArtistWikipediaInfo(extract: extract, pageUrl: pageUrl);
  }
}
