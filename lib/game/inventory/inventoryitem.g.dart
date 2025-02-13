// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventoryitem.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 0;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      item: fields[0] as Item,
      isEquipped: fields[1] as bool,
      isNew: fields[2] as bool,
      quantity: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.item)
      ..writeByte(1)
      ..write(obj.isEquipped)
      ..writeByte(2)
      ..write(obj.isNew)
      ..writeByte(3)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
