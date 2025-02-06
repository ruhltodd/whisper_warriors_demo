// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'umbral_fang.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UmbralFangAdapter extends TypeAdapter<UmbralFang> {
  @override
  final int typeId = 1;

  @override
  UmbralFang read(BinaryReader reader) {
    return UmbralFang();
  }

  @override
  void write(BinaryWriter writer, UmbralFang obj) {
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
      other is UmbralFangAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
