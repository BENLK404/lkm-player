// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_player_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedPlayerStateAdapter extends TypeAdapter<SavedPlayerState> {
  @override
  final int typeId = 3;

  @override
  SavedPlayerState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPlayerState(
      queueIds: (fields[0] as List).cast<String>(),
      currentIndex: fields[1] as int,
      positionMs: fields[2] as int,
      isShuffled: fields[3] as bool,
      repeatModeIndex: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPlayerState obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.queueIds)
      ..writeByte(1)
      ..write(obj.currentIndex)
      ..writeByte(2)
      ..write(obj.positionMs)
      ..writeByte(3)
      ..write(obj.isShuffled)
      ..writeByte(4)
      ..write(obj.repeatModeIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPlayerStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
