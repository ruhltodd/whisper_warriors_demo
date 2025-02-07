// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package:whisper_warriors/game/items/veil_of_the_forgotten.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VeilOfTheForgottenAdapter extends TypeAdapter<VeilOfTheForgotten> {
  @override
  final int typeId = 2;

  @override
  VeilOfTheForgotten read(BinaryReader reader) {
    return VeilOfTheForgotten();
  }

  @override
  void write(BinaryWriter writer, VeilOfTheForgotten obj) {
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
      other is VeilOfTheForgottenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
