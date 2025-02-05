import 'package:hive/hive.dart';

part 'inventoryitem.g.dart'; // ✅ Ensure this is included

@HiveType(typeId: 0) // ✅ Assign a unique type ID
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String rarity;

  @HiveField(3)
  final Map<String, double> stats; // ✅ Stores buffs (Attack, Defense, etc.)

  @HiveField(4)
  bool isEquipped; // ✅ Fix: Add this field

  InventoryItem({
    required this.name,
    required this.description,
    required this.rarity,
    required this.stats,
    this.isEquipped = false, // ✅ Default to unequipped
  });

  // ✅ Equip or Unequip the item
  void toggleEquip() {
    isEquipped = !isEquipped;
    save(); // ✅ Save change to Hive
  }
}
