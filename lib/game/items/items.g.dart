// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 99;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      name: fields[0] as String,
      description: fields[1] as String,
      rarity: fields[2] as String,
      stats: (fields[3] as Map).cast<String, double>(),
      expValue: fields[4] as int,
      spriteName: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
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
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
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
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
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

class GoldCoinAdapter extends TypeAdapter<GoldCoin> {
  @override
  final int typeId = 4;

  @override
  GoldCoin read(BinaryReader reader) {
    return GoldCoin();
  }

  @override
  void write(BinaryWriter writer, GoldCoin obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoldCoinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlueCoinAdapter extends TypeAdapter<BlueCoin> {
  @override
  final int typeId = 5;

  @override
  BlueCoin read(BinaryReader reader) {
    return BlueCoin();
  }

  @override
  void write(BinaryWriter writer, BlueCoin obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlueCoinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GreenCoinAdapter extends TypeAdapter<GreenCoin> {
  @override
  final int typeId = 6;

  @override
  GreenCoin read(BinaryReader reader) {
    return GreenCoin();
  }

  @override
  void write(BinaryWriter writer, GreenCoin obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.rarity)
      ..writeByte(3)
      ..write(obj.stats)
      ..writeByte(4)
      ..write(obj.expValue)
      ..writeByte(5)
      ..write(obj.spriteName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GreenCoinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
