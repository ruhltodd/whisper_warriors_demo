import 'package:hive/hive.dart';
import 'items.dart'; // Your base Item class
import 'player.dart'; // Needed for effect methods
part 'veil_of_the_forgotten.g.dart';

@HiveType(typeId: 2)
class VeilOfTheForgotten extends Item {
  VeilOfTheForgotten()
      : super(
          name: "Veil of the Forgotten",
          description:
              "A mysterious veil that shrouds you in protective darkness.",
          // Example stat: gives a 20% bonus to defense when health is below 50%
          stats: {"Defense Bonus": 0.20},
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
