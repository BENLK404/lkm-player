import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musio/features/music/data/models/song_model.dart';
import 'package:musio/features/music/presentation/providers/music_provider.dart';
import 'package:musio/features/player/presentation/providers/audio_player_provider.dart';
import 'package:musio/features/settings/presentation/providers/settings_provider.dart';

/// Récupère les paroles : .lrc / tags d'abord, puis APIs en ligne si mode online activé.
/// La chanson est cherchée dans la bibliothèque, la piste en cours, puis la file d'attente
/// pour gérer les pistes nouvellement ajoutées ou uniquement en queue.
final lyricsProvider = FutureProvider.family<String?, String>((ref, songId) async {
  final repository = ref.watch(musicRepositoryProvider);

  // Résoudre la chanson : bibliothèque → piste en cours → file d'attente (nouvelles pistes / queue)
  SongModel? song;
  final musicState = ref.watch(musicProvider).valueOrNull;
  if (musicState != null) {
    final list = musicState.songs.where((s) => s.id == songId).toList();
    if (list.isNotEmpty) song = list.first;
  }
  if (song == null) {
    final playerState = ref.watch(audioPlayerProvider);
    if (playerState.currentSong?.id == songId) {
      song = playerState.currentSong;
    } else if (playerState.queue.isNotEmpty) {
      final inQueue = playerState.queue.where((s) => s.id == songId).toList();
      if (inQueue.isNotEmpty) song = inQueue.first;
    }
  }

  // 1) Local : cache + fichier .lrc (avec songOverride pour pistes pas encore en cache)
  final local = await repository.getLyrics(songId, songOverride: song);
  if (local != null && local.trim().isNotEmpty) return local;

  // 2) En ligne : besoin artiste + titre
  final onlineEnabled = ref.watch(onlineFeatureEnabledProvider).valueOrNull ?? true;
  if (!onlineEnabled) return null;
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
