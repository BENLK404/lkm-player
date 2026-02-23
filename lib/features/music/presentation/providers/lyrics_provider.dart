import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

/// Récupère les paroles : .lrc / tags d'abord, puis APIs en ligne si mode online activé.
final lyricsProvider = FutureProvider.family<String?, String>((ref, songId) async {
  final repository = ref.watch(musicRepositoryProvider);

  // 1) Local : fichier .lrc ou tags
  final local = await repository.getLyrics(songId);
  if (local != null && local.trim().isNotEmpty) return local;

  // 2) En ligne : besoin artiste + titre (par défaut true pendant le chargement du réglage)
  final onlineEnabled = ref.watch(onlineFeatureEnabledProvider).valueOrNull ?? true;
  if (!onlineEnabled) return null;

  SongModel? song;
  final musicState = ref.watch(musicProvider).valueOrNull;
  if (musicState != null) {
    final list = musicState.songs.where((s) => s.id == songId).toList();
    if (list.isNotEmpty) song = list.first;
  }
  if (song == null) {
    final playerState = ref.watch(audioPlayerProvider);
    if (playerState.currentSong?.id == songId) song = playerState.currentSong;
  }
  if (song == null || song.artist.isEmpty || song.title.isEmpty) return null;

  final webLyrics = await repository.getLyricsFromWeb(
    song.artist,
    song.title,
    durationMs: song.duration > 0 ? song.duration : null,
    album: song.album.isNotEmpty ? song.album : null,
  );
  if (webLyrics != null && webLyrics.trim().isNotEmpty) {
    await repository.saveLyricsToCache(songId, webLyrics);
  }
  return webLyrics;
});
