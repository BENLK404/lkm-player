// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SongModel _$SongModelFromJson(Map<String, dynamic> json) {
  return _SongModel.fromJson(json);
}

/// @nodoc
mixin _$SongModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get title => throw _privateConstructorUsedError;
  @HiveField(2)
  String get artist => throw _privateConstructorUsedError;
  @HiveField(3)
  String get album => throw _privateConstructorUsedError;
  @HiveField(4)
  String get path => throw _privateConstructorUsedError;
  @HiveField(5)
  int get duration => throw _privateConstructorUsedError; // en millisecondes
  @HiveField(6)
  String? get albumArtPath => throw _privateConstructorUsedError;
  @HiveField(7)
  String? get genre => throw _privateConstructorUsedError;
  @HiveField(8)
  int? get year => throw _privateConstructorUsedError;
  @HiveField(9)
  int? get trackNumber => throw _privateConstructorUsedError;
  @HiveField(10)
  int get playCount => throw _privateConstructorUsedError;
  @HiveField(11)
  DateTime? get lastPlayed => throw _privateConstructorUsedError;
  @HiveField(12)
  bool get isFavorite => throw _privateConstructorUsedError;
  @HiveField(13)
  String? get albumId => throw _privateConstructorUsedError;
  @HiveField(14)
  String? get artistId => throw _privateConstructorUsedError;
  @HiveField(15)
  int? get dateAdded => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SongModelCopyWith<SongModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongModelCopyWith<$Res> {
  factory $SongModelCopyWith(SongModel value, $Res Function(SongModel) then) =
      _$SongModelCopyWithImpl<$Res, SongModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String artist,
      @HiveField(3) String album,
      @HiveField(4) String path,
      @HiveField(5) int duration,
      @HiveField(6) String? albumArtPath,
      @HiveField(7) String? genre,
      @HiveField(8) int? year,
      @HiveField(9) int? trackNumber,
      @HiveField(10) int playCount,
      @HiveField(11) DateTime? lastPlayed,
      @HiveField(12) bool isFavorite,
      @HiveField(13) String? albumId,
      @HiveField(14) String? artistId,
      @HiveField(15) int? dateAdded});
}

/// @nodoc
class _$SongModelCopyWithImpl<$Res, $Val extends SongModel>
    implements $SongModelCopyWith<$Res> {
  _$SongModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? path = null,
    Object? duration = null,
    Object? albumArtPath = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? trackNumber = freezed,
    Object? playCount = null,
    Object? lastPlayed = freezed,
    Object? isFavorite = null,
    Object? albumId = freezed,
    Object? artistId = freezed,
    Object? dateAdded = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtPath: freezed == albumArtPath
          ? _value.albumArtPath
          : albumArtPath // ignore: cast_nullable_to_non_nullable
              as String?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      trackNumber: freezed == trackNumber
          ? _value.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastPlayed: freezed == lastPlayed
          ? _value.lastPlayed
          : lastPlayed // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      albumId: freezed == albumId
          ? _value.albumId
          : albumId // ignore: cast_nullable_to_non_nullable
              as String?,
      artistId: freezed == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as String?,
      dateAdded: freezed == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SongModelImplCopyWith<$Res>
    implements $SongModelCopyWith<$Res> {
  factory _$$SongModelImplCopyWith(
          _$SongModelImpl value, $Res Function(_$SongModelImpl) then) =
      __$$SongModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String artist,
      @HiveField(3) String album,
      @HiveField(4) String path,
      @HiveField(5) int duration,
      @HiveField(6) String? albumArtPath,
      @HiveField(7) String? genre,
      @HiveField(8) int? year,
      @HiveField(9) int? trackNumber,
      @HiveField(10) int playCount,
      @HiveField(11) DateTime? lastPlayed,
      @HiveField(12) bool isFavorite,
      @HiveField(13) String? albumId,
      @HiveField(14) String? artistId,
      @HiveField(15) int? dateAdded});
}

/// @nodoc
class __$$SongModelImplCopyWithImpl<$Res>
    extends _$SongModelCopyWithImpl<$Res, _$SongModelImpl>
    implements _$$SongModelImplCopyWith<$Res> {
  __$$SongModelImplCopyWithImpl(
      _$SongModelImpl _value, $Res Function(_$SongModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? path = null,
    Object? duration = null,
    Object? albumArtPath = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? trackNumber = freezed,
    Object? playCount = null,
    Object? lastPlayed = freezed,
    Object? isFavorite = null,
    Object? albumId = freezed,
    Object? artistId = freezed,
    Object? dateAdded = freezed,
  }) {
    return _then(_$SongModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtPath: freezed == albumArtPath
          ? _value.albumArtPath
          : albumArtPath // ignore: cast_nullable_to_non_nullable
              as String?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      trackNumber: freezed == trackNumber
          ? _value.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastPlayed: freezed == lastPlayed
          ? _value.lastPlayed
          : lastPlayed // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      albumId: freezed == albumId
          ? _value.albumId
          : albumId // ignore: cast_nullable_to_non_nullable
              as String?,
      artistId: freezed == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as String?,
      dateAdded: freezed == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SongModelImpl implements _SongModel {
  const _$SongModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.title,
      @HiveField(2) required this.artist,
      @HiveField(3) required this.album,
      @HiveField(4) required this.path,
      @HiveField(5) required this.duration,
      @HiveField(6) this.albumArtPath,
      @HiveField(7) this.genre,
      @HiveField(8) this.year,
      @HiveField(9) this.trackNumber,
      @HiveField(10) this.playCount = 0,
      @HiveField(11) this.lastPlayed,
      @HiveField(12) this.isFavorite = false,
      @HiveField(13) this.albumId,
      @HiveField(14) this.artistId,
      @HiveField(15) this.dateAdded});

  factory _$SongModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String title;
  @override
  @HiveField(2)
  final String artist;
  @override
  @HiveField(3)
  final String album;
  @override
  @HiveField(4)
  final String path;
  @override
  @HiveField(5)
  final int duration;
// en millisecondes
  @override
  @HiveField(6)
  final String? albumArtPath;
  @override
  @HiveField(7)
  final String? genre;
  @override
  @HiveField(8)
  final int? year;
  @override
  @HiveField(9)
  final int? trackNumber;
  @override
  @JsonKey()
  @HiveField(10)
  final int playCount;
  @override
  @HiveField(11)
  final DateTime? lastPlayed;
  @override
  @JsonKey()
  @HiveField(12)
  final bool isFavorite;
  @override
  @HiveField(13)
  final String? albumId;
  @override
  @HiveField(14)
  final String? artistId;
  @override
  @HiveField(15)
  final int? dateAdded;

  @override
  String toString() {
    return 'SongModel(id: $id, title: $title, artist: $artist, album: $album, path: $path, duration: $duration, albumArtPath: $albumArtPath, genre: $genre, year: $year, trackNumber: $trackNumber, playCount: $playCount, lastPlayed: $lastPlayed, isFavorite: $isFavorite, albumId: $albumId, artistId: $artistId, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.albumArtPath, albumArtPath) ||
                other.albumArtPath == albumArtPath) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.trackNumber, trackNumber) ||
                other.trackNumber == trackNumber) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.albumId, albumId) || other.albumId == albumId) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      artist,
      album,
      path,
      duration,
      albumArtPath,
      genre,
      year,
      trackNumber,
      playCount,
      lastPlayed,
      isFavorite,
      albumId,
      artistId,
      dateAdded);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SongModelImplCopyWith<_$SongModelImpl> get copyWith =>
      __$$SongModelImplCopyWithImpl<_$SongModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongModelImplToJson(
      this,
    );
  }
}

abstract class _SongModel implements SongModel {
  const factory _SongModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String title,
      @HiveField(2) required final String artist,
      @HiveField(3) required final String album,
      @HiveField(4) required final String path,
      @HiveField(5) required final int duration,
      @HiveField(6) final String? albumArtPath,
      @HiveField(7) final String? genre,
      @HiveField(8) final int? year,
      @HiveField(9) final int? trackNumber,
      @HiveField(10) final int playCount,
      @HiveField(11) final DateTime? lastPlayed,
      @HiveField(12) final bool isFavorite,
      @HiveField(13) final String? albumId,
      @HiveField(14) final String? artistId,
      @HiveField(15) final int? dateAdded}) = _$SongModelImpl;

  factory _SongModel.fromJson(Map<String, dynamic> json) =
      _$SongModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get title;
  @override
  @HiveField(2)
  String get artist;
  @override
  @HiveField(3)
  String get album;
  @override
  @HiveField(4)
  String get path;
  @override
  @HiveField(5)
  int get duration;
  @override // en millisecondes
  @HiveField(6)
  String? get albumArtPath;
  @override
  @HiveField(7)
  String? get genre;
  @override
  @HiveField(8)
  int? get year;
  @override
  @HiveField(9)
  int? get trackNumber;
  @override
  @HiveField(10)
  int get playCount;
  @override
  @HiveField(11)
  DateTime? get lastPlayed;
  @override
  @HiveField(12)
  bool get isFavorite;
  @override
  @HiveField(13)
  String? get albumId;
  @override
  @HiveField(14)
  String? get artistId;
  @override
  @HiveField(15)
  int? get dateAdded;
  @override
  @JsonKey(ignore: true)
  _$$SongModelImplCopyWith<_$SongModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
