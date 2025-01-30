import 'package:flame/components.dart';
import 'player.dart';

/// Defines available power-ups
enum PowerUpType {
  vampiricTouch,
  armorUpgrade,
  magnetism,
  blackHole,
  attackSpeedBoost,
  movementSpeedBoost
}

class PowerUp {
  final PowerUpType type;
  int level; // Starts at 1, max level 6

  PowerUp(this.type, {this.level = 1});

  /// Applies the power-up's effect to the player
  void applyEffect(Player player) {
    switch (type) {
      case PowerUpType.vampiricTouch:
        player.vampiricHealing += 2.0 + level; // Scales with level
        break;
      case PowerUpType.armorUpgrade:
        player.damageReduction += 0.05 * level; // Reduces damage taken
        break;
      case PowerUpType.magnetism:
        player.magnetRange += 20 * level; // Increases XP/item pickup range
        break;
      case PowerUpType.blackHole:
        player.blackHoleCooldown = (player.blackHoleCooldown - 1.5)
            .clamp(3.0, 10.0); // Ensures cooldown never goes below 3 seconds
        break;
      case PowerUpType.attackSpeedBoost: // ✅ Scales attack speed per level
        player.firingCooldown = (player.firingCooldown * (1 - (level * 0.05)))
            .clamp(0.3, 1.0); // Reduces cooldown, speeds up attack
        break;
      case PowerUpType.movementSpeedBoost: // ✅ Scales movement speed per level
        player.speed +=
            (5.0 * level); // Increases movement speed with each level
        break;
    }
  }

  /// Returns a readable name for the power-up
  String get name {
    switch (type) {
      case PowerUpType.vampiricTouch:
        return "🩸 Vampiric Touch (Lvl $level)";
      case PowerUpType.armorUpgrade:
        return "🛡 Armor Upgrade (Lvl $level)";
      case PowerUpType.magnetism:
        return "🧲 Magnetism (Lvl $level)";
      case PowerUpType.blackHole:
        return "🌀 Black Hole (Lvl $level)";
      case PowerUpType.attackSpeedBoost: // ✅ Added Attack Speed icon
        return "⚡ Attack Speed (Lvl $level)";
      case PowerUpType.movementSpeedBoost: // ✅ Added Movement Speed icon
        return "👟 Movement Speed (Lvl $level)";
    }
  }
}
