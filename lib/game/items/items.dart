import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/player/player.dart';

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
@HiveType(typeId: 1) // ✅ Unique typeId
class UmbralFang extends Item {
  UmbralFang()
      : super(
          name: "Umbral Fang",
          description:
              "A dagger formed from pure shadow, phasing through enemies.",
          rarity: "Rare",
          stats: {"Attack Speed": 0.20, "Piercing": 1},
          expValue: 200,
          spriteName: 'umbral_fang.png',
        );

  @override
  void applyEffect(Player player) {
    player.baseAttackSpeed *= 1.15;
    player.projectilesShouldPierce = true; // ✅ Enable piercing
    print(
        "🗡️ Umbral Fang equipped! Attack speed increased & projectiles pierce!");
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
          description: "A spectral robe woven from lost memories.",
          rarity: "Epic",
          stats: {"Defense Bonus": 0.20, "Threshold": 0.50},
          expValue: 300,
          spriteName: 'veil_of_the_forgotten.png',
        );

  @override
  void applyEffect(Player player) {
    print(
        "🌀 Veil of the Forgotten equipped! Damage reduction active when HP < 50%");
  }

  @override
  void removeEffect(Player player) {
    print("🌀 Veil of the Forgotten unequipped.");
  }
}

// 💠 **Shard of Umbrathos - Boosts Spirit Multiplier by 15%**
@HiveType(typeId: 3) // ✅ Unique typeId
class ShardOfUmbrathos extends Item {
  ShardOfUmbrathos()
      : super(
          name: "Shard of Umbrathos",
          description:
              "A fragment of the Fading King’s power, still pulsing with energy.",
          rarity: "Legendary",
          stats: {"Spirit Multiplier": 0.30},
          expValue: 400,
          spriteName: 'shard_of_umbrathos.png',
        );

  @override
  void applyEffect(Player player) {
    player.spiritMultiplier *= 1.15;
    print("💠 Shard of Umbrathos equipped! Spirit Multiplier increased!");
  }

  @override
  void removeEffect(Player player) {
    player.spiritMultiplier /= 1.15;
    print("💠 Shard of Umbrathos unequipped.");
  }
}
