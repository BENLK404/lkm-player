import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';

/// Lance la lecture d’un morceau déjà présent en bibliothèque (ID interne).
void playSingleSongFromLibrary(WidgetRef ref, String songId) {
  final songs = ref.read(allSongsProvider);
  final index = songs.indexWhere((s) => s.id == songId);
  if (index < 0) return;
  ref.read(audioPlayerProvider.notifier).play([songs[index]], 0);
}

/// Lance la lecture de toutes les pistes d’un album téléchargé depuis Deezer
/// (`albumId` des [SongModel] = ID album Deezer).
void playAlbumFromLibraryByDeezerId(WidgetRef ref, String deezerAlbumId) {
  final songs = ref
      .read(allSongsProvider)
      .where((s) => s.albumId == deezerAlbumId)
      .toList()
    ..sort(
      (a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0),
    );
  if (songs.isEmpty) return;
  ref.read(audioPlayerProvider.notifier).play(songs, 0);
}

/// ID bibliothèque pour une piste issue du téléchargement unitaire Deezer.
String librarySongIdForDeezerTrack(String deezerTrackId) =>
    'deezer_$deezerTrackId';
