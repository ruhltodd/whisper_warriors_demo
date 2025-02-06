import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/inventoryitem.dart';
import 'inventory.dart';
import 'player.dart';

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
  /// ✅ Equip an item
  static void equipItem(String itemName, Player player) {
    // We no longer need to worry about null here, just check if the item is found
    for (var item in _inventoryBox.values) {
      if (item.name == itemName) {
        item.isEquipped = true;
        item.save(); // Save the equipped status in the Hive box
        print("⚔️ Equipped: $itemName");

        // Apply effects of the equipped item here if needed
        item.applyEffect(player); // Pass the player to apply the effect
      } else {
        item.isEquipped = false;
        item.save();
      }
    }
  }

  /// ✅ Unequip an item
  static void unequipItem(String itemName) {
    // Ensure we handle null item safely
    final item = _inventoryBox.get(itemName);
    if (item != null) {
      item.isEquipped = false;
      item.save();
      print("❌ Unequipped: $itemName");
    } else {
      print("⚠️ Item not found: $itemName");
    }
  }

  /// ✅ Load inventory from Hive
  static List<InventoryItem> getInventory() {
    // Ensuring the list is non-nullable and can handle empty states
    return _inventoryBox.values.toList();
  }

  /// ✅ Get currently equipped items
  static List<InventoryItem> getEquippedItems() {
    return _inventoryBox.values.where((item) => item.isEquipped).toList();
  }
}
