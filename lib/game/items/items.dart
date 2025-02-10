import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';

part 'items.g.dart'; // ✅ Required for Hive TypeAdapter Generation

@HiveType(typeId: 99) // ✅ Unique ID for the base class
abstract class Item extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String rarity;

  @HiveField(3)
  final Map<String, double> stats;

  @HiveField(4)
  final int expValue;

  @HiveField(5)
  final String spriteName;

  Item({
    required this.name,
    required this.description,
    required this.rarity,
    required this.stats,
    required this.expValue,
    required this.spriteName,
  });

  void applyEffect(Player player);
  void removeEffect(Player player);
}

// 🗡️ **Umbral Fang - Increases attack speed & allows piercing**
@HiveType(typeId: 1) // ✅ Ensure it's unique in Hive
class UmbralFang extends Item {
  UmbralFang()
      : super(
          name: "Umbral Fang",
          description:
              "A dagger formed from pure shadow, phasing through enemies.",
          rarity: "Rare",
          stats: {"Attack Speed": 0.15, "Piercing": 1}, // ✅ Standardized Stats
          expValue: 200,
          spriteName: "umbral_fang.png", // ✅ Proper sprite filename
        );

  @override
  void applyEffect(Player player) {
    player.baseAttackSpeed *= 1.15;
    player.projectilesShouldPierce = true; // ✅ Enable piercing

    print(
        "🗡️ Umbral Fang equipped! Attack speed increased & projectiles pierce!");

    // ✅ Ensure already-fired projectiles update if needed
    for (var projectile in player.gameRef.children.whereType<Projectile>()) {
      projectile.shouldPierce = true;
    }
  }

  @override
  void removeEffect(Player player) {
    player.baseAttackSpeed /= 1.15;
    player.projectilesShouldPierce = false; // ✅ Disable piercing
    print("🗡️ Umbral Fang unequipped. Projectiles no longer pierce.");
  }
}

// 🏹 **Veil of the Forgotten - Reduces damage when below 50% HP**
@HiveType(typeId: 2) // ✅ Unique typeId
class VeilOfTheForgotten extends Item {
  VeilOfTheForgotten()
      : super(
          name: "Veil of the Forgotten",
          description:
              "A mysterious veil that shrouds you in protective darkness.",
          // Example stat: gives a 20% bonus to defense when health is below 50%
          stats: {"Defense Bonus": 0.20},
          expValue: 100, // Example value for experience points
          spriteName: "veil_of_the_forgotten.png", // Example sprite name
          rarity: "Epic",
        );

  @override
  void applyEffect(Player player) {
    // For example, increase defense if player's health is below 50% of max
    if (player.currentHealth < player.maxHealth * 0.5) {
      player.baseDefense *= (1 + stats["Defense Bonus"]!);
    }
    print("Applied Veil of the Forgotten effect to player.");
  }

  @override
  void removeEffect(Player player) {
    // Reverse the effect (if applicable)
    if (player.currentHealth < player.maxHealth * 0.5) {
      player.baseDefense /= (1 + stats["Defense Bonus"]!);
    }
    print("Removed Veil of the Forgotten effect from player.");
  }
}

// 💠 **Shard of Umbrathos - Boosts Spirit Multiplier by 15%**
@HiveType(typeId: 3) // ✅ Unique typeId
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

@HiveType(typeId: 4) // ✅ Unique typeId
class GoldCoin extends Item {
  GoldCoin()
      : super(
          name: "Gold Coin",
          description: "A shiny gold coin.",
          rarity: "Common",
          stats: {},
          expValue: 5000,
          spriteName: 'gold_coin.png',
        );

  @override
  void applyEffect(Player player) {
    // Define any effects if needed
  }

  @override
  void removeEffect(Player player) {
    // Define any removal effects if needed
  }
}

@HiveType(typeId: 5) // ✅ Unique typeId
class BlueCoin extends Item {
  BlueCoin()
      : super(
          name: "Blue Coin",
          description: "A shiny blue coin.",
          rarity: "Common",
          stats: {},
          expValue: 10,
          spriteName: 'blue_coin.png',
        );

  @override
  void applyEffect(Player player) {
    // Define any effects if needed
  }

  @override
  void removeEffect(Player player) {
    // Define any removal effects if needed
  }
}
