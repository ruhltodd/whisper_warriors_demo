import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';

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
    switch (name.toLowerCase()) {
      case 'umbral fang':
        return UmbralFang();
      case 'veil of the forgotten':
        return VeilOfTheForgotten();
      case 'shard of umbrathos':
        return ShardOfUmbrathos();
      case 'gold coin':
        return GoldCoin();
      case 'blue coin':
        return BlueCoin();
      case 'green coin':
        return GreenCoin();
      default:
        return null;
    }
  }
}

class UmbralFang extends Item {
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

class VeilOfTheForgotten extends Item {
  @override
  String get name => 'Veil of the Forgotten';

  @override
  String get description => 'A mysterious veil that whispers ancient secrets.';

  @override
  String get spriteName => 'veil_of_the_forgotten.png';

  @override
  ItemRarity get rarity => ItemRarity.epic;

  @override
  int get expValue => 150; // Added expValue getter with appropriate value

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

class ShardOfUmbrathos extends Item {
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
