import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/inventoryitem.dart';
import 'inventory.dart';

class InventoryManager {
  static final Box<InventoryItem> _inventoryBox =
      Hive.box<InventoryItem>('inventoryBox');

  /// ✅ Add an item to inventory
  static void addItem(InventoryItem item) {
    _inventoryBox.put(item.name, item);
    print("👜 Item added: ${item.name}");
  }

  /// ✅ Remove an item from inventory
  static void removeItem(String itemName) {
    _inventoryBox.delete(itemName);
    print("🗑️ Item removed: $itemName");
  }

  /// ✅ Equip an item
  static void equipItem(String itemName) {
    for (var item in _inventoryBox.values) {
      if (item.name == itemName) {
        item.isEquipped = true;
        item.save();
        print("⚔️ Equipped: $itemName");
      } else {
        item.isEquipped = false; // Unequip other items of the same type
        item.save();
      }
    }
  }

  /// ✅ Unequip an item
  static void unequipItem(String itemName) {
    final item = _inventoryBox.get(itemName);
    if (item != null) {
      item.isEquipped = false;
      item.save();
      print("❌ Unequipped: $itemName");
    }
  }

  /// ✅ Load inventory from Hive
  static List<InventoryItem> getInventory() {
    return _inventoryBox.values.toList();
  }

  /// ✅ Get currently equipped items
  static List<InventoryItem> getEquippedItems() {
    return _inventoryBox.values.where((item) => item.isEquipped).toList();
  }
}
