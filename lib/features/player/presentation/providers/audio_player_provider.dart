import 'package:musio/features/music/data/models/song_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/player_state.dart';
import '../../data/services/audio_player_service.dart';

part 'audio_player_provider.g.dart';

@Riverpod(keepAlive: true)
class AudioPlayer extends _$AudioPlayer {
  late AudioPlayerService _audioPlayerService;

  @override
  PlayerState build() {
    _audioPlayerService = ref.watch(audioPlayerServiceProvider);

    // Écouter les changements d'état du service
    _audioPlayerService.stateStream.listen((newState) {
      state = newState;
    });

    return _audioPlayerService.currentState;
  }

  void play(List<SongModel> songs, int startIndex) {
    _audioPlayerService.play(songs, startIndex);
  }

  void pause() {
    _audioPlayerService.pause();
  }

  void resume() {
    _audioPlayerService.resume();
  }

  void seek(Duration position) {
    // Mise à jour immédiate de l'UI (évite que la barre reparte en arrière au release du slider)
    state = state.copyWith(position: position);
    _audioPlayerService.seek(position);
  }

  void next() {
    _audioPlayerService.next();
  }

  void previous() {
    _audioPlayerService.previous();
  }

  void toggleShuffle() {
    _audioPlayerService.toggleShuffle();
  }

  void toggleRepeat() {
    _audioPlayerService.toggleRepeat();
  }

  void skipToIndex(int index) {
    _audioPlayerService.skipToIndex(index);
  }

  void addNext(SongModel song) {
    _audioPlayerService.addNext(song);
  }

  void addToQueue(SongModel song) {
    _audioPlayerService.addToQueue(song);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _audioPlayerService.reorderQueue(oldIndex, newIndex);
  }

  void setSpeed(double speed) {
    _audioPlayerService.setSpeed(speed);
  }
}

/// Provider singleton pour le service audio
@Riverpod(keepAlive: true)
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) {
  final service = AudioPlayerService(ref);

  // Nettoyer le service quand le provider est disposé
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
