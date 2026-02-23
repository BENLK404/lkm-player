import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../music/data/models/song_model.dart';

part 'player_state.freezed.dart';

/// État global du lecteur audio
@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    SongModel? currentSong,
    @Default([]) List<SongModel> queue,
    @Default(0) int currentIndex,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(false) bool isPlaying,
    @Default(false) bool isLoading,
    @Default(RepeatMode.off) RepeatMode repeatMode,
    @Default(false) bool isShuffled,
    @Default(1.0) double playbackSpeed,
    @Default(1.0) double volume,
  }) = _PlayerState;
}

/// Mode de répétition
enum RepeatMode {
  off,     // Pas de répétition
  one,     // Répéter la chanson actuelle
  all,     // Répéter toute la queue
}
