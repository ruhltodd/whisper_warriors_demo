import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';

abstract class Item {
  String get name;
  String get description;
  String get spriteName;
  ItemRarity get rarity;
  String get spritePath => 'items/$name.png'; // Default sprite path pattern
  Map<String, double> stats = {};
  int get expValue;

  void updateStats(Map<String, double> newStats) {
    stats = Map<String, double>.from(newStats);
    print('📊 Updated stats for $name: $stats');
  }

  double getStat(String statName) {
    return stats[statName] ?? 0.0;
  }

  void applyEffect(Player player) {
    // Default implementation - can be overridden by subclasses
    // No effect by default
  }

  void removeEffect(Player player) {
    // Default implementation - can be overridden by subclasses
    // No effect by default
  }

  static Item? createByName(String name) {
    Item? item;
    switch (name.toLowerCase()) {
      case 'umbral fang':
        item = UmbralFang();
        item.stats = {
          "Attack Speed": 0.15,
          "Pierce": 1.0,
        };
        break;
      case 'veil of the forgotten':
        item = VeilOfTheForgotten();
        item.stats = {
          "Defense Bonus": 0.50,
          "Spirit Bonus": 0.25,
        };
        break;
      case 'shard of umbrathos':
        item = ShardOfUmbrathos();
        item.stats = {
          "Spirit Multiplier": 0.35,
          "Dark Power": 0.25,
        };
        break;
      case 'gold coin':
        item = GoldCoin();
        break;
      case 'blue coin':
        item = BlueCoin();
        break;
      case 'green coin':
        item = GreenCoin();
        break;
    }
    return item;
  }
}

class UmbralFang extends Item {
  UmbralFang() {
    stats = {
      "Attack Speed": 0.15, // 15% attack speed increase
      "Pierce": 1.0, // 100% chance to pierce (boolean represented as 1.0)
    };
  }

  @override
  String get name => 'Umbral Fang';

  @override
  String get description => 'A shadowy fang that pulses with dark energy.';

  @override
  String get spriteName => 'umbral_fang.png';

  @override
  ItemRarity get rarity => ItemRarity.rare;

  @override
  String get spritePath => 'umbral_fang.png';

  @override
  int get expValue => 100;

  @override
  void applyEffect(Player player) {
    player.baseAttackSpeed *= (1 + stats["Attack Speed"]!);
    player.projectilesShouldPierce = true;

    print(
        "🗡️ Umbral Fang equipped! Attack speed increased & projectiles pierce!");

    // Ensure already-fired projectiles update if needed
    for (var projectile in player.gameRef.children.whereType<Projectile>()) {
      projectile.shouldPierce = true;
    }
  }

  @override
  void removeEffect(Player player) {
    player.baseAttackSpeed /= (1 + stats["Attack Speed"]!);
    player.projectilesShouldPierce = false;
    print("🗡️ Umbral Fang unequipped. Projectiles no longer pierce.");
  }
}

class VeilOfTheForgotten extends Item {
  VeilOfTheForgotten() {
    stats = {
      "Defense Bonus": 0.50, // 50% defense increase when below half health
      "Spirit Bonus": 0.25, // 25% spirit bonus
    };
  }

  @override
  String get name => 'Veil of the Forgotten';

  @override
  String get description => 'A mysterious veil that whispers ancient secrets.';

  @override
  String get spriteName => 'veil_of_the_forgotten.png';

  @override
  ItemRarity get rarity => ItemRarity.epic;

  @override
  int get expValue => 150;

  @override
  void applyEffect(Player player) {
    // For example, increase defense if player's health is below 50% of max
    if (player.currentHealth < player.maxHealth * 0.5) {
      player.baseDefense *= (1 + stats["Defense Bonus"]!);
    }

    // Apply spirit bonus through PlayerProgressManager
    double currentBonus = PlayerProgressManager.getSpiritItemBonus();
    PlayerProgressManager.setSpiritItemBonus(
        currentBonus + stats["Spirit Bonus"]!);

    print("Applied Veil of the Forgotten effect to player.");
  }

  @override
  void removeEffect(Player player) {
    // Reverse all effects
    if (player.currentHealth < player.maxHealth * 0.5) {
      player.baseDefense /= (1 + stats["Defense Bonus"]!);
    }

    // Remove spirit bonus through PlayerProgressManager
    double currentBonus = PlayerProgressManager.getSpiritItemBonus();
    PlayerProgressManager.setSpiritItemBonus(
        currentBonus - stats["Spirit Bonus"]!);

    print("Removed Veil of the Forgotten effect from player.");
  }
}

class ShardOfUmbrathos extends Item {
  ShardOfUmbrathos() {
    stats = {
      "Spirit Multiplier": 0.35, // 35% spirit multiplier increase
    };
  }

  @override
  String get name => 'Shard of Umbrathos';

  @override
  String get description => 'A fragment of pure darkness.';

  @override
  String get spriteName => 'shard_of_umbrathos.png';

  @override
  ItemRarity get rarity => ItemRarity.epic;

  @override
  int get expValue => 200;

  @override
  void applyEffect(Player player) {
    if (player.hasEffect("ShardOfUmbrathos")) {
      print("⚠️ Shard of Umbrathos already applied. Skipping.");
      return;
    }

    double bonus = 0.15; // 15% boost
    double currentBonus = PlayerProgressManager.getSpiritItemBonus();
    PlayerProgressManager.setSpiritItemBonus(currentBonus + bonus);

    player.addEffect(
        "ShardOfUmbrathos"); // Store to prevent duplicate applications
    print("✅ Applied Shard of Umbrathos (+15% Spirit)");
  }

  @override
  void removeEffect(Player player) {
    if (!player.hasEffect("ShardOfUmbrathos")) {
      print("⚠️ Shard of Umbrathos not found. Skipping removal.");
      return;
    }

    double bonus = 0.15; // Same 15% boost
    double currentBonus = PlayerProgressManager.getSpiritItemBonus();
    PlayerProgressManager.setSpiritItemBonus(currentBonus - bonus);

    player.removeEffect("ShardOfUmbrathos");
    print("✅ Removed Shard of Umbrathos (-15% Spirit)");
  }
}

class GoldCoin extends Item {
  @override
  String get name => 'Gold Coin';

  @override
  String get description => 'A shiny gold coin.';

  @override
  String get spriteName => 'gold_coin.png';

  @override
  ItemRarity get rarity => ItemRarity.common;

  @override
  String get spritePath => 'gold_coin.png';

  @override
  int get expValue => 5000;

  @override
  void applyEffect(Player player) {
    // Define any effects if needed
  }

  @override
  void removeEffect(Player player) {
    // Define any removal effects if needed
  }
}

class BlueCoin extends Item {
  @override
  String get name => 'Blue Coin';

  @override
  String get description => 'A mysterious blue coin.';

  @override
  String get spriteName => 'blue_coin.png';

  @override
  ItemRarity get rarity => ItemRarity.rare;

  @override
  String get spritePath => 'blue_coin.png';

  @override
  int get expValue => 80;

  @override
  void applyEffect(Player player) {
    // Define any effects if needed
  }

  @override
  void removeEffect(Player player) {
    // Define any removal effects if needed
  }
}

class GreenCoin extends Item {
  @override
  String get name => 'Green Coin';

  @override
  String get description => 'An ethereal green coin.';

  @override
  String get spriteName => 'green_coin.png';

  @override
  ItemRarity get rarity => ItemRarity.uncommon;

  @override
  String get spritePath => 'green_coin.png';

  @override
  int get expValue => 160;

  @override
  void applyEffect(Player player) {
    // Define any effects if needed
  }

  @override
  void removeEffect(Player player) {
    // Define any removal effects if needed
  }
}
