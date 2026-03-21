import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:musio/features/artist/data/models/artist_wikipedia_info.dart';
import 'package:musio/features/artist/data/services/wikipedia_artist_service.dart';

final _artistWikipediaCacheBoxProvider = Provider<Box>((ref) {
  return Hive.box('artist_wikipedia_cache');
});

final wikipediaArtistServiceProvider = Provider<WikipediaArtistService>((ref) {
  final box = ref.watch(_artistWikipediaCacheBoxProvider);
  return WikipediaArtistService(box);
});

/// Fournit les informations Wikipedia pour un artiste (nom). Utilise le cache puis l'API.
final artistWikipediaInfoProvider =
    FutureProvider.family<ArtistWikipediaInfo?, String>((ref, artistName) async {
  final service = ref.watch(wikipediaArtistServiceProvider);
  return service.getArtistInfo(artistName);
});
