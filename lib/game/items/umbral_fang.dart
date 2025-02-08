import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/items/items.dart'; // Your base Item class
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart'; // Needed for effect methods
part 'package:whisper_warriors/game/items/umbral_fang.g.dart';

@HiveType(typeId: 1) // Use a unique typeId (different from InventoryItem)
class UmbralFang extends Item {
  UmbralFang()
      : super(
          name: "Umbral Fang",
          description: "A dark blade forged from the essence of shadows.",
          expValue: 100, // Example value for expValue
          spriteName: "umbral_fang_sprite", // Example value for spriteName
          stats: {"Attack Speed": 0.15}, // ✅ Keeps attack speed bonus
          rarity: "Rare",
        );

  @override
  void applyEffect(Player player) {
    // ✅ 1. Increase Attack Speed
    player.baseAttackSpeed *= (1 + stats["Attack Speed"]!);

    print(
        "🛠️ Player's equipped items: ${player.equippedItems.map((e) => e.name).toList()}");

    print(
        "📌 projectilesShouldPierce BEFORE: ${player.projectilesShouldPierce}");

    // ✅ 2. Enable Piercing for Player Projectiles
    player.projectilesShouldPierce = true;
    print("🗡️ Umbral Fang equipped - projectiles now pierce!");

    // ✅ 3. Ensure already-fired projectiles update if needed
    for (var projectile in player.gameRef.children.whereType<Projectile>()) {
      projectile.shouldPierce = true;
    }
  }

  @override
  void removeEffect(Player player) {
    // ✅ 1. Reverse Attack Speed Bonus
    player.baseAttackSpeed /= (1 + stats["Attack Speed"]!);

    // ✅ 2. Disable Piercing
    player.projectilesShouldPierce = false;
    print("⚔️ Umbral Fang removed - projectiles no longer pierce.");

    // ✅ 3. Update existing projectiles
    for (var projectile in player.gameRef.children.whereType<Projectile>()) {
      projectile.shouldPierce = false;
    }
  }
}
