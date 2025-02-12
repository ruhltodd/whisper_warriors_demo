import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';

class InventoryManager {
  static final Box<InventoryItem> _inventoryBox =
      Hive.box<InventoryItem>('inventoryBox');

  /// Add an item to inventory
  static void addItem(InventoryItem item) {
    if (item.item is! GoldCoin &&
        item.item is! BlueCoin &&
        item.item is! GreenCoin) {
      // First add to box, then save
      _inventoryBox.put(item.name, item);
      item.save(); // Now it's safe to save since the item is in the box
      print("👜 Item added: ${item.name}");

      // Debug: Print current inventory state after adding
      debugPrintInventory();
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
        // Only unequip previously equipped items
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

  /// Load inventory from Hive with state verification
  static List<InventoryItem> getInventory() {
    try {
      final items = _inventoryBox.values.toList();
      // Verify each item's state and ensure it's properly saved
      for (var item in items) {
        if (!_inventoryBox.containsKey(item.name)) {
          _inventoryBox.put(item.name, item);
        }
      }
      print("📦 Loaded ${items.length} items from inventory");
      return items;
    } catch (e) {
      print("⚠️ Error loading inventory: $e");
      return [];
    }
  }

  /// Get currently equipped items
  static List<InventoryItem> getEquippedItems() {
    return _inventoryBox.values.where((item) => item.isEquipped).toList();
  }

  /// Initialize or verify inventory state
  static void initializeInventory() {
    try {
      final items = _inventoryBox.values.toList();

      // Verify existing items only
      for (var item in items) {
        // Ensure each item's state is properly saved
        if (!_inventoryBox.containsKey(item.name)) {
          _inventoryBox.put(item.name, item);
        }
        item.save();
        print("📦 Verified item: ${item.name} (Equipped: ${item.isEquipped})");
      }
      print("✅ Inventory initialized with ${items.length} items");
    } catch (e) {
      print("⚠️ Error initializing inventory: $e");
    }
  }

  /// Debug method to print current inventory state
  static void debugPrintInventory() {
    final items = _inventoryBox.values.toList();
    print("📦 Current Inventory State:");
    for (var item in items) {
      print("- ${item.name} (Equipped: ${item.isEquipped})");
    }
  }
}
