import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'artist_model.freezed.dart';
part 'artist_model.g.dart';

/// Modèle représentant un artiste
@freezed
@HiveType(typeId: 2)
class ArtistModel with _$ArtistModel {
  const factory ArtistModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) String? imagePath,
    @HiveField(3) @Default([]) List<String> albumIds,
    @HiveField(4) @Default([]) List<String> songIds,
    @HiveField(5) @Default(0) int trackCount,
    @HiveField(6) @Default(0) int albumCount,
  }) = _ArtistModel;

  factory ArtistModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistModelFromJson(json);
}
