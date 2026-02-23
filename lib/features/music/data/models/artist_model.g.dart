// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtistModelAdapter extends TypeAdapter<ArtistModel> {
  @override
  final int typeId = 2;

  @override
  ArtistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtistModel(
      id: fields[0] as String,
      name: fields[1] as String,
      imagePath: fields[2] as String?,
      albumIds: (fields[3] as List).cast<String>(),
      songIds: (fields[4] as List).cast<String>(),
      trackCount: fields[5] as int,
      albumCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ArtistModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.albumIds)
      ..writeByte(4)
      ..write(obj.songIds)
      ..writeByte(5)
      ..write(obj.trackCount)
      ..writeByte(6)
      ..write(obj.albumCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistModelImpl _$$ArtistModelImplFromJson(Map<String, dynamic> json) =>
    _$ArtistModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['image_path'] as String?,
      albumIds: (json['album_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      songIds: (json['song_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      albumCount: (json['album_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ArtistModelImplToJson(_$ArtistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_path': instance.imagePath,
      'album_ids': instance.albumIds,
      'song_ids': instance.songIds,
      'track_count': instance.trackCount,
      'album_count': instance.albumCount,
    };
