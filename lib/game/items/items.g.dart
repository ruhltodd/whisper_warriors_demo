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
    final int type = reader.readByte(); // Read the type first
    switch (type) {
      case 1:
        return UmbralFang();
      case 2:
        return VeilOfTheForgotten();
      case 3:
        return ShardOfUmbrathos();
      case 4:
        return GoldCoin();
      case 5:
        return BlueCoin();
      default:
        throw HiveError("Unknown Item Type: $type");
    }
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    if (obj is UmbralFang) {
      writer.writeByte(1);
    } else if (obj is VeilOfTheForgotten) {
      writer.writeByte(2);
    } else if (obj is ShardOfUmbrathos) {
      writer.writeByte(3);
    } else if (obj is GoldCoin) {
      writer.writeByte(4);
    } else if (obj is BlueCoin) {
      writer.writeByte(5);
    } else {
      throw HiveError("Unknown Item Type: ${obj.runtimeType}");
    }

    writer
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
      ..writeByte(4)
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
      ..writeByte(4)
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
      ..writeByte(4)
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
      ..writeByte(4)
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
      ..writeByte(4)
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
