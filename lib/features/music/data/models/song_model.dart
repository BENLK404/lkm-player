import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'song_model.freezed.dart';
part 'song_model.g.dart';

/// Modèle représentant une chanson avec ses métadonnées
@freezed
@HiveType(typeId: 0)
class SongModel with _$SongModel {
  const factory SongModel({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required String artist,
    @HiveField(3) required String album,
    @HiveField(4) required String path,
    @HiveField(5) required int duration, // en millisecondes
    @HiveField(6) String? albumArtPath,
    @HiveField(7) String? genre,
    @HiveField(8) int? year,
    @HiveField(9) int? trackNumber,
    @HiveField(10) @Default(0) int playCount,
    @HiveField(11) DateTime? lastPlayed,
    @HiveField(12) @Default(false) bool isFavorite,
    @HiveField(13) String? albumId,
    @HiveField(14) String? artistId,
    @HiveField(15) int? dateAdded, // Timestamp d'ajout
  }) = _SongModel;

  factory SongModel.fromJson(Map<String, dynamic> json) =>
      _$SongModelFromJson(json);
}
