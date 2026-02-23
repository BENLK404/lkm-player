import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'album_model.freezed.dart';
part 'album_model.g.dart';

/// Modèle représentant un album
@freezed
@HiveType(typeId: 1)
class AlbumModel with _$AlbumModel {
  const factory AlbumModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String artist,
    @HiveField(3) String? albumArtPath,
    @HiveField(4) int? year,
    @HiveField(5) @Default([]) List<String> songIds, // IDs des chansons
    @HiveField(6) @Default(0) int trackCount,
  }) = _AlbumModel;

  factory AlbumModel.fromJson(Map<String, dynamic> json) =>
      _$AlbumModelFromJson(json);
}
