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
      item: fields[0] as Item, // ✅ Deserialize Item instance
      isEquipped: fields[1] as bool, // ✅ Read equipped status
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(2) // ✅ Adjust number of fields
      ..writeByte(0)
      ..write(obj.item) // ✅ Serialize Item instance
      ..writeByte(1)
      ..write(obj.isEquipped); // ✅ Serialize equipped status
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
