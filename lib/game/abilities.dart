import 'package:flame/components.dart';
import 'player.dart';
import 'enemy.dart';
import 'dart:math';
import 'damagenumber.dart';
import 'fireaura.dart';
import 'dart:collection';
import 'explosion.dart';
import 'experience.dart';

/// Enum for ability types (optional, for categorization)
enum AbilityType { passive, onHit, onKill, aura, scaling }

/// Base class for all abilities
abstract class Ability {
  final String name;
  final String description;
  final AbilityType type;

  Ability({
    required this.name,
    required this.description,
    required this.type,
  });

  void applyEffect(Player player) {}
  void onKill(Player player, Vector2 enemyPosition) {}
  void onUpdate(Player player, double dt) {}
}

class WhisperingFlames extends Ability {
  double baseDamagePerSecond = 10.0; // 🔥 Base value (scaled by Spirit)
  double range = 100.0;

  WhisperingFlames()
      : super(
          name: "Whispering Flames",
          description: "A fire aura that burns enemies near you.",
          type: AbilityType.aura,
        );

  @override
  void applyEffect(Player player) {
    super.applyEffect(player);
    player.gameRef.add(FireAura(player: player)); // ✅ Add Fire Aura Effect
  }

  @override
  void onUpdate(Player player, double dt) {
    if (player.gameRef == null) return;

    // ✅ Scale damage with Spirit Level
    double scaledDamage = baseDamagePerSecond * player.spiritMultiplier;

    for (var enemy in player.gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - player.position).length;

      if (distance < range) {
        // ✅ Calculate Critical Strike
        bool isCritical =
            player.gameRef.random.nextDouble() < player.critChance / 100;
        int finalDamage = isCritical
            ? (scaledDamage * player.critMultiplier).toInt()
            : scaledDamage.toInt();

        enemy.takeDamage(finalDamage,
            isCritical: isCritical); // ✅ Pass crit info
      }
    }
  }

  /// Rolls to determine if this hit is a critical strike
  bool _rollCriticalStrike(Player player) {
    return (player.gameRef.random.nextDouble() * 100) < player.critChance;
  }
}

class SoulFracture extends Ability {
  SoulFracture()
      : super(
          name: "Soul Fracture",
          description: "Enemies explode into ghostly shrapnel on death.",
          type: AbilityType.onKill,
        );

  @override
  void onKill(Player player, Vector2 enemyPosition) {
    if (!player.hasTriggeredExplosionRecently()) {
      player.triggerExplosion(enemyPosition);
    }
  }
}

// ✅ Explosion now scales with Spirit Level
extension ExplosionCooldown on Player {
  bool hasTriggeredExplosionRecently() {
    double currentTime = gameRef.currentTime();

    if (currentTime - lastExplosionTime < explosionCooldown) {
      return true;
    }

    lastExplosionTime = currentTime;
    return false;
  }

  void triggerExplosion(Vector2 position) {
    double currentTime = gameRef.currentTime();

    if (currentTime - lastExplosionTime < explosionCooldown) {
      return;
    }

    lastExplosionTime = currentTime;

    gameRef.add(Explosion(position));
    print("💥 Spirit Explosion triggered at $position");

    // ✅ Explosion damage scales with Spirit Level
    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;

      if (distance < 100.0) {
        int damage = (10.0 * spiritMultiplier).toInt().clamp(1, 9999);
        enemy.takeDamage(damage);
        print("🔥 Explosion hit enemy for $damage damage!");
      }
    }
  }
}
/*
class FadingCrescent extends Ability {
  FadingCrescent()
      : super(
          name: "Fading Crescent",
          description: "Deals more damage with fewer abilities left.",
          type: AbilityType.Scaling,
        );

  @override
  void applyEffect(Player player) {
    // Increase damage based on the number of remaining abilities
    player.updateDamageScaling();
  }
}

class VampiricTouch extends Ability {
  VampiricTouch()
      : super(
          name: "Vampiric Touch",
          description: "Heal 5% of enemy HP on kill.",
          type: AbilityType.OnKill,
        );

  @override
  void onKill(Player player, Vector2 enemyPosition) {
    player.heal(0.05); // Heal 5% of max HP per kill
  }
}

class UnholyFortitude extends Ability {
  UnholyFortitude()
      : super(
          name: "Unholy Fortitude",
          description: "Damage taken is converted into temporary HP.",
          type: AbilityType.Passive,
        );

  @override
  void applyEffect(Player player) {
    player.convertDamageToTempHP();
  }
}

class WillOfTheForgotten extends Ability {
  UnholyFortitude()
      : super(
          name: "Will of the Forgotten",
          description: "The fewer abilities left, the stronger you get.",
          type: AbilityType.Passive,
        );

  @override
  void applyEffect(Player player) {
    player.lessAbilitiesStrongerBase();
  }
}

  @override
  void applyEffect(Player player) {
    super.applyEffect(player);
    player.gameRef.add(FireAura(player: player)); // ✅ Add Fire Aura Effect
  }
*/
