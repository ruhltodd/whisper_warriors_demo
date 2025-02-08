import 'package:hive/hive.dart';
import 'items.dart'; // Import your base Item class
import 'package:whisper_warriors/game/player/player.dart'; // Import Player if needed for the effect methods
part 'package:whisper_warriors/game/items/shard_of_umbrathos.g.dart';

@HiveType(typeId: 3)
class ShardOfUmbrathos extends Item {
  // Provide the required values to the super constructor.
  ShardOfUmbrathos()
      : super(
          name: "Shard of Umbrathos",
          description: "A mysterious shard that enhances your spirit.",
          stats: {"Spirit Multiplier": 0.15}, // Example stat bonus
          rarity: "Epic",
          expValue: 100, // Example expValue
          spriteName: "shard_of_umbrathos.png", // Example spriteName
        );

  @override
  void applyEffect(Player player) {
    // For example, increase the player's spirit multiplier.
    player.spiritMultiplier *= (1 + stats["Spirit Multiplier"]!);
    print("Applied ShardOfUmbrathos effect to player.");
  }

  @override
  void removeEffect(Player player) {
    // Reverse the effect when the item is removed.
    player.spiritMultiplier /= (1 + stats["Spirit Multiplier"]!);
    print("Removed ShardOfUmbrathos effect from player.");
  }
}
