// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ability_damage_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AbilityDamageLogAdapter extends TypeAdapter<AbilityDamageLog> {
  @override
  final int typeId = 7;

  @override
  AbilityDamageLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AbilityDamageLog(
      fields[0] as String,
    )
      ..totalDamage = fields[1] as int
      ..hits = fields[2] as int
      ..criticalHits = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, AbilityDamageLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.abilityName)
      ..writeByte(1)
      ..write(obj.totalDamage)
      ..writeByte(2)
      ..write(obj.hits)
      ..writeByte(3)
      ..write(obj.criticalHits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbilityDamageLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
