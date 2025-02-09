import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';

class InventoryManager {
  static final Box<InventoryItem> _inventoryBox =
      Hive.box<InventoryItem>('inventoryBox');

  /// Add an item to inventory
  static void addItem(InventoryItem item) {
    if (item.item is! GoldCoin && item.item is! BlueCoin) {
      // ✅ Skip saving GoldCoin and BlueCoin
      _inventoryBox.put(item.name, item);
      print("👜 Item added: ${item.name}");
    } else {
      print("⚠️ GoldCoin not saved to inventory.");
    }
  }

  /// Remove an item from inventory
  static void removeItem(String itemName) {
    _inventoryBox.delete(itemName);
    print("🗑️ Item removed: $itemName");
  }

  /// Equip an item
  static void equipItem(String itemName, Player player) {
    bool itemFound = false;

    for (var item in _inventoryBox.values) {
      if (item.name == itemName) {
        if (!item.isEquipped) {
          item.isEquipped = true;
          item.save(); // Save the equipped status in the Hive box
          item.applyEffect(player); // Apply effects of the equipped item
          print("⚔️ Equipped: $itemName");
        }
        itemFound = true;
      } else if (item.isEquipped) {
        item.isEquipped = false;
        item.save();
      }
    }

    if (!itemFound) {
      print("⚠️ Item not found: $itemName");
    }
  }

  /// Unequip an item
  static void unequipItem(String itemName) {
    final item = _inventoryBox.get(itemName);
    if (item != null && item.isEquipped) {
      item.isEquipped = false;
      item.save();
      print("❌ Unequipped: $itemName");
    } else {
      print("⚠️ Item not found or not equipped: $itemName");
    }
  }

  /// Load inventory from Hive
  static List<InventoryItem> getInventory() {
    return _inventoryBox.values.toList();
  }

  /// Get currently equipped items
  static List<InventoryItem> getEquippedItems() {
    return _inventoryBox.values.where((item) => item.isEquipped).toList();
  }
}
