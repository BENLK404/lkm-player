import 'package:hive/hive.dart';

part 'saved_player_state.g.dart';

@HiveType(typeId: 3)
class SavedPlayerState extends HiveObject {
  @HiveField(0)
  final List<String> queueIds;

  @HiveField(1)
  final int currentIndex;

  @HiveField(2)
  final int positionMs;

  @HiveField(3)
  final bool isShuffled;

  @HiveField(4)
  final int repeatModeIndex; // 0: off, 1: one, 2: all

  SavedPlayerState({
    required this.queueIds,
    required this.currentIndex,
    required this.positionMs,
    required this.isShuffled,
    required this.repeatModeIndex,
  });
}
