// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package:whisper_warriors/game/items/shard_of_umbrathos.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShardOfUmbrathosAdapter extends TypeAdapter<ShardOfUmbrathos> {
  @override
  final int typeId = 3;

  @override
  ShardOfUmbrathos read(BinaryReader reader) {
    return ShardOfUmbrathos();
  }

  @override
  void write(BinaryWriter writer, ShardOfUmbrathos obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShardOfUmbrathosAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
