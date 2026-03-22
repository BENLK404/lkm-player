// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MusicLibraryState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<SongModel> get songs => throw _privateConstructorUsedError;
  List<AlbumModel> get albums => throw _privateConstructorUsedError;
  List<ArtistModel> get artists => throw _privateConstructorUsedError;
  List<PlaylistModel> get playlists => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MusicLibraryStateCopyWith<MusicLibraryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicLibraryStateCopyWith<$Res> {
  factory $MusicLibraryStateCopyWith(
          MusicLibraryState value, $Res Function(MusicLibraryState) then) =
      _$MusicLibraryStateCopyWithImpl<$Res, MusicLibraryState>;
  @useResult
  $Res call(
      {bool isLoading,
      List<SongModel> songs,
      List<AlbumModel> albums,
      List<ArtistModel> artists,
      List<PlaylistModel> playlists});
}

/// @nodoc
class _$MusicLibraryStateCopyWithImpl<$Res, $Val extends MusicLibraryState>
    implements $MusicLibraryStateCopyWith<$Res> {
  _$MusicLibraryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? songs = null,
    Object? albums = null,
    Object? artists = null,
    Object? playlists = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      songs: null == songs
          ? _value.songs
          : songs // ignore: cast_nullable_to_non_nullable
              as List<SongModel>,
      albums: null == albums
          ? _value.albums
          : albums // ignore: cast_nullable_to_non_nullable
              as List<AlbumModel>,
      artists: null == artists
          ? _value.artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<ArtistModel>,
      playlists: null == playlists
          ? _value.playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MusicLibraryStateImplCopyWith<$Res>
    implements $MusicLibraryStateCopyWith<$Res> {
  factory _$$MusicLibraryStateImplCopyWith(_$MusicLibraryStateImpl value,
          $Res Function(_$MusicLibraryStateImpl) then) =
      __$$MusicLibraryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      List<SongModel> songs,
      List<AlbumModel> albums,
      List<ArtistModel> artists,
      List<PlaylistModel> playlists});
}

/// @nodoc
class __$$MusicLibraryStateImplCopyWithImpl<$Res>
    extends _$MusicLibraryStateCopyWithImpl<$Res, _$MusicLibraryStateImpl>
    implements _$$MusicLibraryStateImplCopyWith<$Res> {
  __$$MusicLibraryStateImplCopyWithImpl(_$MusicLibraryStateImpl _value,
      $Res Function(_$MusicLibraryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? songs = null,
    Object? albums = null,
    Object? artists = null,
    Object? playlists = null,
  }) {
    return _then(_$MusicLibraryStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      songs: null == songs
          ? _value._songs
          : songs // ignore: cast_nullable_to_non_nullable
              as List<SongModel>,
      albums: null == albums
          ? _value._albums
          : albums // ignore: cast_nullable_to_non_nullable
              as List<AlbumModel>,
      artists: null == artists
          ? _value._artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<ArtistModel>,
      playlists: null == playlists
          ? _value._playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistModel>,
    ));
  }
}

/// @nodoc

class _$MusicLibraryStateImpl implements _MusicLibraryState {
  const _$MusicLibraryStateImpl(
      {this.isLoading = false,
      final List<SongModel> songs = const [],
      final List<AlbumModel> albums = const [],
      final List<ArtistModel> artists = const [],
      final List<PlaylistModel> playlists = const []})
      : _songs = songs,
        _albums = albums,
        _artists = artists,
        _playlists = playlists;

  @override
  @JsonKey()
  final bool isLoading;
  final List<SongModel> _songs;
  @override
  @JsonKey()
  List<SongModel> get songs {
    if (_songs is EqualUnmodifiableListView) return _songs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songs);
  }

  final List<AlbumModel> _albums;
  @override
  @JsonKey()
  List<AlbumModel> get albums {
    if (_albums is EqualUnmodifiableListView) return _albums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albums);
  }

  final List<ArtistModel> _artists;
  @override
  @JsonKey()
  List<ArtistModel> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<PlaylistModel> _playlists;
  @override
  @JsonKey()
  List<PlaylistModel> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  @override
  String toString() {
    return 'MusicLibraryState(isLoading: $isLoading, songs: $songs, albums: $albums, artists: $artists, playlists: $playlists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicLibraryStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._songs, _songs) &&
            const DeepCollectionEquality().equals(other._albums, _albums) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality()
                .equals(other._playlists, _playlists));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      const DeepCollectionEquality().hash(_songs),
      const DeepCollectionEquality().hash(_albums),
      const DeepCollectionEquality().hash(_artists),
      const DeepCollectionEquality().hash(_playlists));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicLibraryStateImplCopyWith<_$MusicLibraryStateImpl> get copyWith =>
      __$$MusicLibraryStateImplCopyWithImpl<_$MusicLibraryStateImpl>(
          this, _$identity);
}

abstract class _MusicLibraryState implements MusicLibraryState {
  const factory _MusicLibraryState(
      {final bool isLoading,
      final List<SongModel> songs,
      final List<AlbumModel> albums,
      final List<ArtistModel> artists,
      final List<PlaylistModel> playlists}) = _$MusicLibraryStateImpl;

  @override
  bool get isLoading;
  @override
  List<SongModel> get songs;
  @override
  List<AlbumModel> get albums;
  @override
  List<ArtistModel> get artists;
  @override
  List<PlaylistModel> get playlists;
  @override
  @JsonKey(ignore: true)
  _$$MusicLibraryStateImplCopyWith<_$MusicLibraryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
