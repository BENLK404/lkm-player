// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PlayerState {
  SongModel? get currentSong => throw _privateConstructorUsedError;
  List<SongModel> get queue => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  Duration get position => throw _privateConstructorUsedError;
  Duration get duration => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  RepeatMode get repeatMode => throw _privateConstructorUsedError;
  bool get isShuffled => throw _privateConstructorUsedError;
  double get playbackSpeed => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
          PlayerState value, $Res Function(PlayerState) then) =
      _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call(
      {SongModel? currentSong,
      List<SongModel> queue,
      int currentIndex,
      Duration position,
      Duration duration,
      bool isPlaying,
      bool isLoading,
      RepeatMode repeatMode,
      bool isShuffled,
      double playbackSpeed,
      double volume});

  $SongModelCopyWith<$Res>? get currentSong;
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? queue = null,
    Object? currentIndex = null,
    Object? position = null,
    Object? duration = null,
    Object? isPlaying = null,
    Object? isLoading = null,
    Object? repeatMode = null,
    Object? isShuffled = null,
    Object? playbackSpeed = null,
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as SongModel?,
      queue: null == queue
          ? _value.queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<SongModel>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as RepeatMode,
      isShuffled: null == isShuffled
          ? _value.isShuffled
          : isShuffled // ignore: cast_nullable_to_non_nullable
              as bool,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SongModelCopyWith<$Res>? get currentSong {
    if (_value.currentSong == null) {
      return null;
    }

    return $SongModelCopyWith<$Res>(_value.currentSong!, (value) {
      return _then(_value.copyWith(currentSong: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
          _$PlayerStateImpl value, $Res Function(_$PlayerStateImpl) then) =
      __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SongModel? currentSong,
      List<SongModel> queue,
      int currentIndex,
      Duration position,
      Duration duration,
      bool isPlaying,
      bool isLoading,
      RepeatMode repeatMode,
      bool isShuffled,
      double playbackSpeed,
      double volume});

  @override
  $SongModelCopyWith<$Res>? get currentSong;
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
      _$PlayerStateImpl _value, $Res Function(_$PlayerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? queue = null,
    Object? currentIndex = null,
    Object? position = null,
    Object? duration = null,
    Object? isPlaying = null,
    Object? isLoading = null,
    Object? repeatMode = null,
    Object? isShuffled = null,
    Object? playbackSpeed = null,
    Object? volume = null,
  }) {
    return _then(_$PlayerStateImpl(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as SongModel?,
      queue: null == queue
          ? _value._queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<SongModel>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as RepeatMode,
      isShuffled: null == isShuffled
          ? _value.isShuffled
          : isShuffled // ignore: cast_nullable_to_non_nullable
              as bool,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PlayerStateImpl implements _PlayerState {
  const _$PlayerStateImpl(
      {this.currentSong,
      final List<SongModel> queue = const [],
      this.currentIndex = 0,
      this.position = Duration.zero,
      this.duration = Duration.zero,
      this.isPlaying = false,
      this.isLoading = false,
      this.repeatMode = RepeatMode.off,
      this.isShuffled = false,
      this.playbackSpeed = 1.0,
      this.volume = 1.0})
      : _queue = queue;

  @override
  final SongModel? currentSong;
  final List<SongModel> _queue;
  @override
  @JsonKey()
  List<SongModel> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final Duration position;
  @override
  @JsonKey()
  final Duration duration;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final RepeatMode repeatMode;
  @override
  @JsonKey()
  final bool isShuffled;
  @override
  @JsonKey()
  final double playbackSpeed;
  @override
  @JsonKey()
  final double volume;

  @override
  String toString() {
    return 'PlayerState(currentSong: $currentSong, queue: $queue, currentIndex: $currentIndex, position: $position, duration: $duration, isPlaying: $isPlaying, isLoading: $isLoading, repeatMode: $repeatMode, isShuffled: $isShuffled, playbackSpeed: $playbackSpeed, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.currentSong, currentSong) ||
                other.currentSong == currentSong) &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode) &&
            (identical(other.isShuffled, isShuffled) ||
                other.isShuffled == isShuffled) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentSong,
      const DeepCollectionEquality().hash(_queue),
      currentIndex,
      position,
      duration,
      isPlaying,
      isLoading,
      repeatMode,
      isShuffled,
      playbackSpeed,
      volume);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);
}

abstract class _PlayerState implements PlayerState {
  const factory _PlayerState(
      {final SongModel? currentSong,
      final List<SongModel> queue,
      final int currentIndex,
      final Duration position,
      final Duration duration,
      final bool isPlaying,
      final bool isLoading,
      final RepeatMode repeatMode,
      final bool isShuffled,
      final double playbackSpeed,
      final double volume}) = _$PlayerStateImpl;

  @override
  SongModel? get currentSong;
  @override
  List<SongModel> get queue;
  @override
  int get currentIndex;
  @override
  Duration get position;
  @override
  Duration get duration;
  @override
  bool get isPlaying;
  @override
  bool get isLoading;
  @override
  RepeatMode get repeatMode;
  @override
  bool get isShuffled;
  @override
  double get playbackSpeed;
  @override
  double get volume;
  @override
  @JsonKey(ignore: true)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
