import 'dart:math';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';

class LootTable {
  static final Random _random = Random();

  // 🎯 **Define loot table with drop rates**
  static final Map<Item, double> umbrathosLootTable = {
    UmbralFang(): 0.25, // 25% chance
    VeilOfTheForgotten(): 0.25, // 25% chance
    ShardOfUmbrathos(): 0.50, // 50% chance
  };

  // 🎲 **Function to determine dropped item**
  static Item? getRandomLoot() {
    double roll = _random.nextDouble(); // Value between 0.0 and 1.0
    double cumulativeProbability = 0.0;

    for (var entry in umbrathosLootTable.entries) {
      cumulativeProbability += entry.value;
      if (roll < cumulativeProbability) {
        return entry.key; // ✅ Return the item that matches the roll
      }
    }
    return null; // ❌ No item dropped (if probabilities don’t sum to 1.0)
  }
}

// 🎯 **Modify Boss Death Logic to Drop Loot**
void handleBossDefeat(Player player) {
  Item? droppedItem = LootTable.getRandomLoot();
  if (droppedItem != null) {
    print("🎁 Umbrathos dropped: \${droppedItem.name}!");
    player.collectItem(droppedItem);
  } else {
    print("😢 No item dropped this time.");
  }
}
