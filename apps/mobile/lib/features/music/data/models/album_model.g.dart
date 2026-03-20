// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlbumModelAdapter extends TypeAdapter<AlbumModel> {
  @override
  final int typeId = 1;

  @override
  AlbumModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlbumModel(
      id: fields[0] as String,
      name: fields[1] as String,
      artist: fields[2] as String,
      albumArtPath: fields[3] as String?,
      year: fields[4] as int?,
      songIds: (fields[5] as List).cast<String>(),
      trackCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AlbumModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.albumArtPath)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.songIds)
      ..writeByte(6)
      ..write(obj.trackCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumModelImpl _$$AlbumModelImplFromJson(Map<String, dynamic> json) =>
    _$AlbumModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      albumArtPath: json['album_art_path'] as String?,
      year: (json['year'] as num?)?.toInt(),
      songIds: (json['song_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$AlbumModelImplToJson(_$AlbumModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artist': instance.artist,
      'album_art_path': instance.albumArtPath,
      'year': instance.year,
      'song_ids': instance.songIds,
      'track_count': instance.trackCount,
    };
