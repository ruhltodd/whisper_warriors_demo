import 'package:flame/components.dart';
import 'package:whisper_warriors/game/player.dart';

abstract class Item {
  final String name;
  final String description;
  final ItemType type;

  Item({required this.name, required this.description, required this.type});

  /// Override this method to apply item effects when equipped
  void onEquip(Player player) {}

  /// Override this method to remove effects when unequipped
  void onUnequip(Player player) {}
}

enum ItemType { weapon, accessory, armor, consumable }

///legendary sword.. less than 1% drop rate
class Epitaph extends Item {
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
