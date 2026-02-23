import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'playlist_model.freezed.dart';
part 'playlist_model.g.dart';

@freezed
@HiveType(typeId: 1)
class PlaylistModel with _$PlaylistModel {
  const factory PlaylistModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) @Default([]) List<String> songIds,
    @HiveField(3) String? description,
    @HiveField(4) DateTime? dateCreated,
  }) = _PlaylistModel;

  factory PlaylistModel.create({required String name}) {
    return PlaylistModel(
      id: const Uuid().v4(),
      name: name,
      dateCreated: DateTime.now(),
    );
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistModelFromJson(json);
}
