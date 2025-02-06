import 'package:flame/components.dart';
import 'player.dart';

// 🔹 **Base Class for Items**
abstract class Item {
  final String name;
  final String description;
  final String rarity; // ✅ Add rarity field
  final Map<String, double> stats; // ✅ Add stats field

  Item({
    required this.name,
    required this.description,
    required this.rarity, // ✅ Initialize rarity
    required this.stats, // ✅ Initialize stats
  });

  void applyEffect(Player player);
  void removeEffect(Player player);
}

// 🗡️ **Umbral Fang - Increases attack speed & allows piercing**
class UmbralFang extends Item {
  UmbralFang()
      : super(
          name: "Umbral Fang",
          description:
              "A dagger formed from pure shadow, phasing through enemies.",
          rarity: "Rare", // ✅ Set rarity
          stats: {"Attack Speed": 0.15, "Piercing": 1}, // ✅ Define stats
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
class VeilOfTheForgotten extends Item {
  VeilOfTheForgotten()
      : super(
          name: "Veil of the Forgotten",
          description: "A spectral robe woven from lost memories.",
          rarity: "Epic",
          stats: {"Defense Bonus": 0.20, "Threshold": 0.50}, // ✅ Add stats
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
class ShardOfUmbrathos extends Item {
  ShardOfUmbrathos()
      : super(
          name: "Shard of Umbrathos",
          description:
              "A fragment of the Fading King’s power, still pulsing with energy.",
          rarity: "Legendary",
          stats: {"Spirit Multiplier": 0.15}, // ✅ Add stats
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
///legendary sword.. less than 1% drop rate
/*class Epitaph extends Item {
  Epitaph()
      : super(
          name: "Epitaph, Greatsword of Whispers",
          description:
              "A blade forged from lost souls. It murmurs the echoes of forgotten warriors.",
          type: ItemType.weapon,
        );

  @override
  void onEquip(Player player) {
    print("🗡️ Epitaph Equipped!");

    // 🔹 **Apply Whispering Strikes Effect**
    player.attackModifiers.add(WhisperingStrikes());

    // 🔹 **Apply Passive Damage Reduction**
    player.addPassiveEffect(PassiveEffect(
        /*  name: "Veil of the Lost",
      description: "Reduces incoming damage by 20% when below 50% HP.",
      condition: () => player.currentHealth < player.maxHealth * 0.5,
      effect: () => player.defense *= 1.2, // Increase defense by 20%
      removeEffect: () =>
          player.defense /= 1.2,*/ // Reset defense when unequipped
        ));
  }

  @override
  void onUnequip(Player player) {
    print("🗡️ Epitaph Unequipped!");

    // Remove attack modifier
    player.attackModifiers.removeWhere((effect) => effect is WhisperingStrikes);

    // Remove passive damage reduction
    player.removePassiveEffect("Veil of the Lost");
  }
}

class PassiveEffect {}

class WhisperingStrikes extends AttackModifier {
  // WhisperingStrikes() : super(name: "Whispering Strikes");

  @override
  void applyEffect(Player player, PositionComponent target, int damage) {
    if (player.gameRef.random.nextDouble() < 0.15) {
      // 15% proc chance
      Future.delayed(Duration(milliseconds: 150), () {
        if (target.isMounted) {
          print("🔁 Whispering Strike triggered! Repeating attack...");
          player.shootProjectile(target, (damage * 0.5).toInt()); // 50% damage
        }
      });
    }
  }
}

class AttackModifier {}
*/