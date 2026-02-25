import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:musio/features/player/data/models/saved_player_state.dart';
import 'package:musio/core/providers/app_providers.dart';
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/player/data/services/audio_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../../../music/data/models/song_model.dart';
import '../../../music/presentation/providers/music_provider.dart';
import '../models/player_state.dart';

/// Service principal gérant la lecture audio
class AudioPlayerService {
  final MusioAudioHandler _audioHandler;
  final _stateController = BehaviorSubject<PlayerState>.seeded(const PlayerState());
  final Ref _ref;
  
  List<SongModel> _localQueue = [];
  Timer? _saveTimer;
  Duration? _lastSeekPosition;
  DateTime? _lastSeekTime;
  static const _closeMs = 300;
  static const _recoveryMs = 5000;

  AudioPlayerService(this._ref) : _audioHandler = _ref.read(audioHandlerProvider) {
    _initializeListeners();
    _restoreState();
  }

  // Getters
  Stream<PlayerState> get stateStream => _stateController.stream;
  PlayerState get currentState => _stateController.value;
  ja.AndroidEqualizer get equalizer => _audioHandler.equalizer;

  /// Initialise les listeners pour les changements d'état
  void _initializeListeners() {
    Rx.combineLatest4(
      _audioHandler.playbackState,
      _audioHandler.player.sequenceStateStream,
      _audioHandler.player.shuffleModeEnabledStream,
      _audioHandler.player.loopModeStream,
      (playbackState, sequenceState, shuffleModeEnabled, loopMode) => (playbackState, sequenceState, shuffleModeEnabled, loopMode),
    ).listen((data) {
      final (playbackState, sequenceState, shuffleModeEnabled, loopMode) = data;

      final isPlaying = playbackState.playing;
      final isLoading = playbackState.processingState == AudioProcessingState.loading ||
          playbackState.processingState == AudioProcessingState.buffering;
      final newIndex = sequenceState?.currentIndex;
      SongModel? newCurrentSong;
      if (newIndex != null && newIndex < _localQueue.length) {
        newCurrentSong = _localQueue[newIndex];
      }

      final prev = currentState;
      final positionOnly = prev.isPlaying == isPlaying &&
          prev.currentSong?.id == newCurrentSong?.id &&
          prev.currentIndex == (newIndex ?? 0) &&
          prev.isShuffled == shuffleModeEnabled &&
          prev.repeatMode == _mapLoopModeFromJustAudio(loopMode);

      if (newCurrentSong != null && newCurrentSong.id != prev.currentSong?.id) {
        _ref.read(musicProvider.notifier).recordSongPlayed(newCurrentSong);
      }

      var position = playbackState.updatePosition;
      if (_lastSeekPosition != null && _lastSeekTime != null) {
        final diff = (position.inMilliseconds - _lastSeekPosition!.inMilliseconds).abs();
        final elapsed = DateTime.now().difference(_lastSeekTime!).inMilliseconds;
        if (diff <= _closeMs) {
          _lastSeekPosition = null;
          _lastSeekTime = null;
        } else if (elapsed > _recoveryMs) {
          _lastSeekPosition = null;
          _lastSeekTime = null;
        } else {
          position = _lastSeekPosition!;
        }
      }

      _updateState(prev.copyWith(
        isPlaying: isPlaying,
        isLoading: isLoading,
        position: position,
        duration: newCurrentSong?.duration != null ? Duration(milliseconds: newCurrentSong!.duration) : Duration.zero,
        currentSong: newCurrentSong,
        currentIndex: newIndex ?? 0,
        isShuffled: shuffleModeEnabled,
        queue: _localQueue,
        repeatMode: _mapLoopModeFromJustAudio(loopMode),
      ));

      if (!positionOnly) _scheduleSaveState();
    });
  }

  /// Met à jour l'état et notifie les listeners
  void _updateState(PlayerState newState) {
    _stateController.add(newState);
  }

  Future<void> _restoreState() async {
    try {
      final box = Hive.box<SavedPlayerState>('player_state');
      final savedState = box.get('last_state');

      if (savedState != null && savedState.queueIds.isNotEmpty) {
        // Récupérer les chansons complètes depuis le repository
        final repository = _ref.read(musicRepositoryProvider);
        final allSongs = await repository.getSongsFromCache();
        final songMap = {for (var s in allSongs) s.id: s};

        final restoredQueue = savedState.queueIds
            .map((id) => songMap[id])
            .whereType<SongModel>()
            .toList();

        if (restoredQueue.isNotEmpty) {
          _localQueue = restoredQueue;
          
          // Restaurer la playlist dans le handler
          await _audioHandler.loadPlaylist(restoredQueue, savedState.currentIndex);
          
          // Restaurer la position
          await _audioHandler.seek(Duration(milliseconds: savedState.positionMs));
          
          // Restaurer le shuffle
          if (savedState.isShuffled) {
             _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
          }
          
          // Restaurer le repeat
          final repeatMode = AudioServiceRepeatMode.values[savedState.repeatModeIndex];
          _audioHandler.setRepeatMode(repeatMode);

          // Ne pas lancer la lecture automatiquement !
          await _audioHandler.pause();
        }
      }
    } catch (e) {
      AppLogger.e('Erreur lors de la restauration de l\'état', error: e);
    }
  }

  void _scheduleSaveState() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveState);
  }

  Future<void> _saveState() async {
    try {
      if (_localQueue.isEmpty) return;

      final box = Hive.box<SavedPlayerState>('player_state');
      final state = currentState;
      
      final savedState = SavedPlayerState(
        queueIds: _localQueue.map((s) => s.id).toList(),
        currentIndex: state.currentIndex,
        positionMs: state.position.inMilliseconds,
        isShuffled: state.isShuffled,
        repeatModeIndex: _mapRepeatModeToAudioService(state.repeatMode).index,
      );

      await box.put('last_state', savedState);
    } catch (e) {
      AppLogger.e('Erreur lors de la sauvegarde de l\'état', error: e);
    }
  }

  /// Charge et joue une liste de chansons
  Future<void> play(List<SongModel> songs, int startIndex) async {
    _localQueue = songs;
    await _audioHandler.loadPlaylist(songs, startIndex);
    await _audioHandler.play();
  }

  /// Pause (mise à jour immédiate, appel natif en arrière-plan)
  void pause() {
    _updateState(currentState.copyWith(isPlaying: false));
    _audioHandler.pause();
  }

  /// Resume (mise à jour immédiate, appel natif en arrière-plan)
  void resume() {
    _updateState(currentState.copyWith(isPlaying: true));
    _audioHandler.play();
  }

  /// Jouer la chanson suivante
  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  /// Jouer la chanson précédente
  Future<void> previous() async {
    await _audioHandler.skipToPrevious();
  }

  /// Aller à un index spécifique dans la file
  Future<void> skipToIndex(int index) async {
    await _audioHandler.player.seek(Duration.zero, index: index);
  }

  /// Seek : mise à jour immédiate de l'UI + appel natif sans attendre
  void seek(Duration position) {
    _lastSeekPosition = position;
    _lastSeekTime = DateTime.now();
    _updateState(currentState.copyWith(position: position));
    _audioHandler.seek(position);
  }

  /// Toggle shuffle
  void toggleShuffle() {
    final newShuffleState = !_audioHandler.player.shuffleModeEnabled;
    _audioHandler.setShuffleMode(newShuffleState ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  /// Changer le mode de répétition
  void toggleRepeat() {
    final currentMode = currentState.repeatMode;
    final newMode = switch (currentMode) {
      RepeatMode.off => AudioServiceRepeatMode.all,
      RepeatMode.all => AudioServiceRepeatMode.one,
      RepeatMode.one => AudioServiceRepeatMode.none,
    };
    _audioHandler.setRepeatMode(newMode);
  }

  /// Réorganiser la file d'attente
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final song = _localQueue.removeAt(oldIndex);
    _localQueue.insert(newIndex, song);
    
    _updateState(currentState.copyWith(queue: _localQueue));
    
    await _audioHandler.moveQueueItem(oldIndex, newIndex);
  }

  /// Changer la vitesse de lecture (1.0, 1.5 ou 2.0)
  Future<void> setSpeed(double speed) async {
    await _audioHandler.setSpeed(speed);
    _updateState(currentState.copyWith(playbackSpeed: speed));
  }

  /// Ajouter une chanson comme suivante dans la file
  Future<void> addNext(SongModel song) async {
    _localQueue.insert(currentState.currentIndex + 1, song);
    await _audioHandler.addNext(song);
  }

  /// Ajouter une chanson à la fin de la file
  Future<void> addToQueue(SongModel song) async {
    _localQueue.add(song);
    await _audioHandler.addToQueue(song);
  }

  RepeatMode _mapLoopModeFromJustAudio(ja.LoopMode mode) {
    return switch (mode) {
      ja.LoopMode.off => RepeatMode.off,
      ja.LoopMode.one => RepeatMode.one,
      ja.LoopMode.all => RepeatMode.all,
    };
  }

  AudioServiceRepeatMode _mapRepeatModeToAudioService(RepeatMode mode) {
    return switch (mode) {
      RepeatMode.off => AudioServiceRepeatMode.none,
      RepeatMode.one => AudioServiceRepeatMode.one,
      RepeatMode.all => AudioServiceRepeatMode.all,
    };
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _saveTimer?.cancel();
    await _audioHandler.stop();
    await _stateController.close();
  }
}
