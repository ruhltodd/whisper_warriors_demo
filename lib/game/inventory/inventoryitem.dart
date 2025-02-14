import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';

class InventoryItem {
  final Item item;
  bool isEquipped;
  bool isNew;
  int quantity;

  // Add getters that forward to item properties
  String get name => item.name;
  String get description => item.description;
  ItemRarity get rarity => item.rarity;
  Map<String, double> get stats => item.stats;

  InventoryItem({
    required this.item,
    this.isEquipped = false,
    this.isNew = true,
    this.quantity = 1,
  });

  // Factory method to create a new inventory item
  static Future<InventoryItem> create({
    required Item item,
    bool isEquipped = false,
    bool isNew = true,
    int quantity = 1,
  }) async {
    final inventoryItem = InventoryItem(
      item: item,
      isEquipped: isEquipped,
      isNew: isNew,
      quantity: quantity,
    );

    // Load current inventory and add new item
    final currentItems = await InventoryStorage.loadInventory();
    currentItems.add(inventoryItem);
    await InventoryStorage.saveInventory(currentItems);

    return inventoryItem;
  }

  Future<void> updateItemStats(Map<String, double> newStats) async {
    item.updateStats(newStats);
    await _saveInventoryUpdate();
    print('✨ Updated and saved stats for ${item.name}');
  }

  Future<void> _saveInventoryUpdate() async {
    try {
      final currentItems = await InventoryStorage.loadInventory();
      final index = currentItems.indexWhere((i) => i.item.name == item.name);

      if (index != -1) {
        currentItems[index] = this;
        await InventoryStorage.saveInventory(currentItems);
        print('✅ Saved inventory update for ${item.name}');
      } else {
        print('⚠️ Item ${item.name} not found in inventory');
      }
    } catch (e) {
      print('❌ Error saving inventory update: $e');
    }
  }

  Future<void> toggleEquip(Player player) async {
    isEquipped = !isEquipped;

    if (isEquipped) {
      applyEffect(player);
    } else {
      removeEffect(player);
    }

    await _saveInventoryUpdate();
    print("🔄 ${item.name} equipped state changed to: $isEquipped");
  }

  void applyEffect(Player player) {
    print("🎮 Applying effects of $name");

    stats.forEach((stat, value) {
      switch (stat) {
        case 'health':
          player.setMaxHealth(player.getMaxHealth() + value);
          player.setHealth(player.getMaxHealth());
          break;
        case 'speed':
          player.setMoveSpeed(player.getMoveSpeed() + value);
          break;
        case 'damage':
          player.setDamageMultiplier(player.getDamageMultiplier() + value);
          break;
      }
    });
  }

  void removeEffect(Player player) {
    print("🎮 Removing effects of $name");

    stats.forEach((stat, value) {
      switch (stat) {
        case 'health':
          player.setMaxHealth(player.getMaxHealth() - value);
          player.setHealth(player.getMaxHealth());
          break;
        case 'speed':
          player.setMoveSpeed(player.getMoveSpeed() - value);
          break;
        case 'damage':
          player.setDamageMultiplier(player.getDamageMultiplier() - value);
          break;
      }
    });
  }

  String getStatsDisplay() {
    final stats = item.stats;
    if (stats.isEmpty) return 'No stats';

    return stats.entries.map((entry) {
      final value = entry.value.toStringAsFixed(1);
      return '${entry.key}: $value';
    }).join('\n');
  }
}
