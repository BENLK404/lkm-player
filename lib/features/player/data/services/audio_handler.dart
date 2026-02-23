import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musio/core/utils/app_logger.dart';
import 'package:musio/features/music/data/models/song_model.dart';

class MusioAudioHandler extends BaseAudioHandler with SeekHandler {
  late final AudioPlayer _player;
  final _playlist = ConcatenatingAudioSource(children: []);
  final AndroidEqualizer _equalizer = AndroidEqualizer();

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
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenToPlaybackState() {
    _player.positionStream.listen((position) {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(updatePosition: position));
    });
    
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
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
