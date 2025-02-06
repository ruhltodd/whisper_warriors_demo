import 'package:hive/hive.dart';
import 'items.dart'; // Your base Item class
import 'player.dart'; // Needed for effect methods
part 'umbral_fang.g.dart';

@HiveType(typeId: 1) // Use a unique typeId (different from InventoryItem)
class UmbralFang extends Item {
  UmbralFang()
      : super(
          name: "Umbral Fang",
          description: "A dark blade forged from the essence of shadows.",
          // Example stat: increases attack speed by 15%
          stats: {"Attack Speed": 0.15},
          rarity: "Rare",
        );

  @override
  void applyEffect(Player player) {
    // Increase the player's base attack speed by 15%
    player.baseAttackSpeed *= (1 + stats["Attack Speed"]!);
    print("Applied Umbral Fang effect to player.");
  }

  @override
  void removeEffect(Player player) {
    // Reverse the effect on attack speed
    player.baseAttackSpeed /= (1 + stats["Attack Speed"]!);
    print("Removed Umbral Fang effect from player.");
  }
}
