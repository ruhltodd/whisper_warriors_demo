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

  Item({
    required this.name,
    required this.description,
    required this.rarity,
    required this.stats,
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
          stats: {"Attack Speed": 0.15, "Piercing": 1},
        );

  @override
  void applyEffect(Player player) {
    player.baseAttackSpeed *= 1.15;
    print(
        "🗡️ Umbral Fang equipped! Attack speed increased & projectiles pierce!");
  }

  @override
  void removeEffect(Player player) {
    player.baseAttackSpeed /= 1.15;
    print("🗡️ Umbral Fang unequipped.");
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
          stats: {"Spirit Multiplier": 0.15},
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
