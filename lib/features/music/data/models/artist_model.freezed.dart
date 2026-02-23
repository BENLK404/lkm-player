// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistModel _$ArtistModelFromJson(Map<String, dynamic> json) {
  return _ArtistModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get imagePath => throw _privateConstructorUsedError;
  @HiveField(3)
  List<String> get albumIds => throw _privateConstructorUsedError;
  @HiveField(4)
  List<String> get songIds => throw _privateConstructorUsedError;
  @HiveField(5)
  int get trackCount => throw _privateConstructorUsedError;
  @HiveField(6)
  int get albumCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistModelCopyWith<ArtistModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistModelCopyWith<$Res> {
  factory $ArtistModelCopyWith(
          ArtistModel value, $Res Function(ArtistModel) then) =
      _$ArtistModelCopyWithImpl<$Res, ArtistModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String? imagePath,
      @HiveField(3) List<String> albumIds,
      @HiveField(4) List<String> songIds,
      @HiveField(5) int trackCount,
      @HiveField(6) int albumCount});
}

/// @nodoc
class _$ArtistModelCopyWithImpl<$Res, $Val extends ArtistModel>
    implements $ArtistModelCopyWith<$Res> {
  _$ArtistModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imagePath = freezed,
    Object? albumIds = null,
    Object? songIds = null,
    Object? trackCount = null,
    Object? albumCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      albumIds: null == albumIds
          ? _value.albumIds
          : albumIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      songIds: null == songIds
          ? _value.songIds
          : songIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trackCount: null == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int,
      albumCount: null == albumCount
          ? _value.albumCount
          : albumCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistModelImplCopyWith<$Res>
    implements $ArtistModelCopyWith<$Res> {
  factory _$$ArtistModelImplCopyWith(
          _$ArtistModelImpl value, $Res Function(_$ArtistModelImpl) then) =
      __$$ArtistModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String? imagePath,
      @HiveField(3) List<String> albumIds,
      @HiveField(4) List<String> songIds,
      @HiveField(5) int trackCount,
      @HiveField(6) int albumCount});
}

/// @nodoc
class __$$ArtistModelImplCopyWithImpl<$Res>
    extends _$ArtistModelCopyWithImpl<$Res, _$ArtistModelImpl>
    implements _$$ArtistModelImplCopyWith<$Res> {
  __$$ArtistModelImplCopyWithImpl(
      _$ArtistModelImpl _value, $Res Function(_$ArtistModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? imagePath = freezed,
    Object? albumIds = null,
    Object? songIds = null,
    Object? trackCount = null,
    Object? albumCount = null,
  }) {
    return _then(_$ArtistModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      albumIds: null == albumIds
          ? _value._albumIds
          : albumIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      songIds: null == songIds
          ? _value._songIds
          : songIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trackCount: null == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int,
      albumCount: null == albumCount
          ? _value.albumCount
          : albumCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistModelImpl implements _ArtistModel {
  const _$ArtistModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) this.imagePath,
      @HiveField(3) final List<String> albumIds = const [],
      @HiveField(4) final List<String> songIds = const [],
      @HiveField(5) this.trackCount = 0,
      @HiveField(6) this.albumCount = 0})
      : _albumIds = albumIds,
        _songIds = songIds;

  factory _$ArtistModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String? imagePath;
  final List<String> _albumIds;
  @override
  @JsonKey()
  @HiveField(3)
  List<String> get albumIds {
    if (_albumIds is EqualUnmodifiableListView) return _albumIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albumIds);
  }

  final List<String> _songIds;
  @override
  @JsonKey()
  @HiveField(4)
  List<String> get songIds {
    if (_songIds is EqualUnmodifiableListView) return _songIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songIds);
  }

  @override
  @JsonKey()
  @HiveField(5)
  final int trackCount;
  @override
  @JsonKey()
  @HiveField(6)
  final int albumCount;

  @override
  String toString() {
    return 'ArtistModel(id: $id, name: $name, imagePath: $imagePath, albumIds: $albumIds, songIds: $songIds, trackCount: $trackCount, albumCount: $albumCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            const DeepCollectionEquality().equals(other._albumIds, _albumIds) &&
            const DeepCollectionEquality().equals(other._songIds, _songIds) &&
            (identical(other.trackCount, trackCount) ||
                other.trackCount == trackCount) &&
            (identical(other.albumCount, albumCount) ||
                other.albumCount == albumCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      imagePath,
      const DeepCollectionEquality().hash(_albumIds),
      const DeepCollectionEquality().hash(_songIds),
      trackCount,
      albumCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      __$$ArtistModelImplCopyWithImpl<_$ArtistModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistModel implements ArtistModel {
  const factory _ArtistModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) final String? imagePath,
      @HiveField(3) final List<String> albumIds,
      @HiveField(4) final List<String> songIds,
      @HiveField(5) final int trackCount,
      @HiveField(6) final int albumCount}) = _$ArtistModelImpl;

  factory _ArtistModel.fromJson(Map<String, dynamic> json) =
      _$ArtistModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String? get imagePath;
  @override
  @HiveField(3)
  List<String> get albumIds;
  @override
  @HiveField(4)
  List<String> get songIds;
  @override
  @HiveField(5)
  int get trackCount;
  @override
  @HiveField(6)
  int get albumCount;
  @override
  @JsonKey(ignore: true)
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
