import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/music/data/models/song_model.dart';

class MusioAudioHandler extends BaseAudioHandler with SeekHandler {
  late final AudioPlayer _player;
  final _playlist = ConcatenatingAudioSource(children: []);
  final AndroidEqualizer _equalizer = AndroidEqualizer();

  /// Après un seek(S), on n'envoie jamais une position "en retard" : on garde S jusqu'à ce que le stream envoie une valeur proche.
  Duration? _lastSeekPosition;
  DateTime? _seekTime;
  static const _closeMs = 300;
  static const _recoveryMs = 5000;

  MusioAudioHandler() {
    _player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]));
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPlaybackState();
  }

  // Exposer le lecteur et l'égaliseur
  AudioPlayer get player => _player;
  AndroidEqualizer get equalizer => _equalizer;
  ConcatenatingAudioSource get playlist => _playlist;

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      AppLogger.e('Erreur chargement playlist vide', error: e);
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final useSeekPos = _lastSeekPosition != null;
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: useSeekPos ? _lastSeekPosition! : _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenToPlaybackState() {
    _player.positionStream.listen((position) {
      Duration toShow = position;
      if (_lastSeekPosition != null && _seekTime != null) {
        final diff = (position.inMilliseconds - _lastSeekPosition!.inMilliseconds).abs();
        final elapsed = DateTime.now().difference(_seekTime!).inMilliseconds;
        if (diff <= _closeMs) {
          _lastSeekPosition = null;
          _seekTime = null;
        } else if (elapsed > _recoveryMs) {
          _lastSeekPosition = null;
          _seekTime = null;
        } else {
          toShow = _lastSeekPosition!;
        }
      }
      playbackState.add(playbackState.value.copyWith(updatePosition: toShow));
    });
    
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  @override
  Future<void> play() async {
    // Mise à jour immédiate pour la notification (play/pause réactif)
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
    ));
    return _player.play();
  }

  @override
  Future<void> pause() async {
    // Mise à jour immédiate pour la notification (play/pause réactif)
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _lastSeekPosition = position;
    _seekTime = DateTime.now();
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    _lastSeekPosition = null;
    _seekTime = null;
    await _player.stop();
    return super.stop();
  }
  
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) {
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.group: LoopMode.all,
      AudioServiceRepeatMode.all: LoopMode.all,
    }[repeatMode]!;
    await _player.setLoopMode(loopMode);
  }

  // Méthode personnalisée pour charger une playlist
  Future<void> loadPlaylist(List<SongModel> songs, int initialIndex) async {
    final mediaItems = songs.map((song) => _createMediaItem(song)).toList();
    
    // Mettre à jour la file d'attente d'AudioService
    queue.add(mediaItems);
    
    // Afficher tout de suite le morceau courant dans la notification (titre, artiste, pochette)
    if (mediaItems.isNotEmpty && initialIndex >= 0 && initialIndex < mediaItems.length) {
      mediaItem.add(mediaItems[initialIndex]);
    }
    
    // Mettre à jour la source audio de just_audio
    await _playlist.clear();
    final audioSources = songs.map((song) => _createAudioSource(song)).toList();
    await _playlist.addAll(audioSources);
    
    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
  }
  
  // Méthode pour réorganiser
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    final newQueue = List<MediaItem>.from(queue.value);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    queue.add(newQueue);
    
    await _playlist.move(oldIndex, newIndex);
  }

  // Méthode pour ajouter une chanson après la chanson courante
  Future<void> addNext(SongModel song) async {
    final mediaItem = _createMediaItem(song);
    final audioSource = _createAudioSource(song);
    
    final currentIndex = _player.currentIndex ?? 0;
    final nextIndex = currentIndex + 1;

    final newQueue = List<MediaItem>.from(queue.value);
    newQueue.insert(nextIndex, mediaItem);
    queue.add(newQueue);

    await _playlist.insert(nextIndex, audioSource);
  }

  // Méthode pour ajouter une chanson à la fin de la file
  Future<void> addToQueue(SongModel song) async {
    final mediaItem = _createMediaItem(song);
    final audioSource = _createAudioSource(song);

    final newQueue = List<MediaItem>.from(queue.value);
    newQueue.add(mediaItem);
    queue.add(newQueue);

    await _playlist.add(audioSource);
  }

  MediaItem _createMediaItem(SongModel song) {
    return MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumArtPath != null ? Uri.file(song.albumArtPath!) : null,
      extras: {'path': song.path},
    );
  }

  AudioSource _createAudioSource(SongModel song) {
    return AudioSource.uri(
      Uri.file(song.path),
      tag: song,
    );
  }
}
