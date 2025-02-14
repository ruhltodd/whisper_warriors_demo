import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';

class InventoryManager {
  /// Add an item to inventory
  static Future<void> addItem(InventoryItem item) async {
    try {
      if (item.item is! GoldCoin &&
          item.item is! BlueCoin &&
          item.item is! GreenCoin) {
        // Load current inventory
        final currentItems = await InventoryStorage.loadInventory();

        // Check if item already exists
        final existingItemIndex =
            currentItems.indexWhere((i) => i.item.name == item.item.name);

        if (existingItemIndex != -1) {
          // Update quantity if item exists
          currentItems[existingItemIndex].quantity += 1;
          print("📦 Updated quantity for: ${item.item.name}");
        } else {
          // Add new item
          currentItems.add(item);
          print("👜 Added new item: ${item.item.name}");
        }

        // Save updated inventory
        await InventoryStorage.saveInventory(currentItems);

        // Debug: Print current inventory state
        await debugPrintInventory();
      } else {
        print("💰 Coin collected, skipping inventory save");
      }
    } catch (e) {
      print("❌ Error adding item: $e");
    }
  }

  /// Remove an item from inventory
  static Future<void> removeItem(String itemName) async {
    try {
      final currentItems = await InventoryStorage.loadInventory();
      currentItems.removeWhere((item) => item.item.name == itemName);
      await InventoryStorage.saveInventory(currentItems);
      print("🗑️ Removed item: $itemName");
    } catch (e) {
      print("❌ Error removing item: $e");
    }
  }

  /// Equip an item
  static Future<void> equipItem(String itemName, Player player) async {
    try {
      final currentItems = await InventoryStorage.loadInventory();
      bool itemFound = false;

      for (var item in currentItems) {
        if (item.item.name == itemName) {
          if (!item.isEquipped) {
            item.isEquipped = true;
            item.applyEffect(player);
            print("⚔️ Equipped: $itemName");
          }
          itemFound = true;
        } else if (item.isEquipped) {
          // Unequip previously equipped items
          item.isEquipped = false;
          item.removeEffect(player);
        }
      }

      if (!itemFound) {
        print("⚠️ Item not found: $itemName");
        return;
      }

      await InventoryStorage.saveInventory(currentItems);
    } catch (e) {
      print("❌ Error equipping item: $e");
    }
  }

  /// Unequip an item
  static Future<void> unequipItem(String itemName, Player player) async {
    try {
      final currentItems = await InventoryStorage.loadInventory();
      final item = currentItems.firstWhere(
        (i) => i.item.name == itemName,
        orElse: () => throw Exception("Item not found"),
      );

      if (item.isEquipped) {
        item.isEquipped = false;
        item.removeEffect(player);
        await InventoryStorage.saveInventory(currentItems);
        print("❌ Unequipped: $itemName");
      } else {
        print("⚠️ Item not equipped: $itemName");
      }
    } catch (e) {
      print("❌ Error unequipping item: $e");
    }
  }

  /// Get all inventory items
  static Future<List<InventoryItem>> getInventory() async {
    try {
      final items = await InventoryStorage.loadInventory();
      print("📦 Loaded ${items.length} items from inventory");
      return items;
    } catch (e) {
      print("❌ Error loading inventory: $e");
      return [];
    }
  }

  /// Get equipped items
  static Future<List<InventoryItem>> getEquippedItems() async {
    try {
      final List<InventoryItem> items = await InventoryStorage.loadInventory();
      return items.where((item) => item.isEquipped).toList();
    } catch (e) {
      print("❌ Error loading equipped items: $e");
      return [];
    }
  }

  /// Debug method to print current inventory state
  static Future<void> debugPrintInventory() async {
    try {
      final items = await InventoryStorage.loadInventory();
      print("\n📦 Current Inventory State:");
      for (var item in items) {
        print("- ${item.item.name}");
        print("  Equipped: ${item.isEquipped}");
        print("  Quantity: ${item.quantity}");
        print("  Stats: ${item.item.stats}\n");
      }
    } catch (e) {
      print("❌ Error printing inventory: $e");
    }
  }
}
