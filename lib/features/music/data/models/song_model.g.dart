// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      path: fields[4] as String,
      duration: fields[5] as int,
      albumArtPath: fields[6] as String?,
      genre: fields[7] as String?,
      year: fields[8] as int?,
      trackNumber: fields[9] as int?,
      playCount: fields[10] as int,
      lastPlayed: fields[11] as DateTime?,
      isFavorite: fields[12] as bool,
      albumId: fields[13] as String?,
      artistId: fields[14] as String?,
      dateAdded: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.path)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.albumArtPath)
      ..writeByte(7)
      ..write(obj.genre)
      ..writeByte(8)
      ..write(obj.year)
      ..writeByte(9)
      ..write(obj.trackNumber)
      ..writeByte(10)
      ..write(obj.playCount)
      ..writeByte(11)
      ..write(obj.lastPlayed)
      ..writeByte(12)
      ..write(obj.isFavorite)
      ..writeByte(13)
      ..write(obj.albumId)
      ..writeByte(14)
      ..write(obj.artistId)
      ..writeByte(15)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongModelImpl _$$SongModelImplFromJson(Map<String, dynamic> json) =>
    _$SongModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      path: json['path'] as String,
      duration: (json['duration'] as num).toInt(),
      albumArtPath: json['album_art_path'] as String?,
      genre: json['genre'] as String?,
      year: (json['year'] as num?)?.toInt(),
      trackNumber: (json['track_number'] as num?)?.toInt(),
      playCount: (json['play_count'] as num?)?.toInt() ?? 0,
      lastPlayed: json['last_played'] == null
          ? null
          : DateTime.parse(json['last_played'] as String),
      isFavorite: json['is_favorite'] as bool? ?? false,
      albumId: json['album_id'] as String?,
      artistId: json['artist_id'] as String?,
      dateAdded: (json['date_added'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SongModelImplToJson(_$SongModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'path': instance.path,
      'duration': instance.duration,
      'album_art_path': instance.albumArtPath,
      'genre': instance.genre,
      'year': instance.year,
      'track_number': instance.trackNumber,
      'play_count': instance.playCount,
      'last_played': instance.lastPlayed?.toIso8601String(),
      'is_favorite': instance.isFavorite,
      'album_id': instance.albumId,
      'artist_id': instance.artistId,
      'date_added': instance.dateAdded,
    };
