import 'package:flame/components.dart';
import 'player.dart';
import 'enemy.dart';
import 'dart:math';
import 'damagenumber.dart';
import 'fireaura.dart';
import 'dart:collection';
import 'explosion.dart';

/// Enum for ability types (optional, for categorization)
enum AbilityType { Passive, OnHit, OnKill, Aura, Scaling }

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
  double damagePerSecond = 10.0;
  double range = 100.0;

  WhisperingFlames()
      : super(
          name: "Whispering Flames",
          description: "A fire aura that burns enemies near you.",
          type: AbilityType.Aura,
        );

  @override
  void applyEffect(Player player) {
    super.applyEffect(player);
    player.gameRef.add(FireAura(player: player)); // ✅ Add Fire Aura Effect
  }

  @override
  void onUpdate(Player player, double dt) {
    if (player.gameRef == null) return;

    for (var enemy in player.gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - player.position).length;
      if (distance < range) {
        int damage = (damagePerSecond * dt).toInt().clamp(1, 9999);
        enemy.takeDamage(damage);
      }
    }
  }
}

class SoulFracture extends Ability {
  SoulFracture()
      : super(
          name: "Soul Fracture",
          description: "Enemies explode into ghostly shrapnel on death.",
          type: AbilityType.OnKill,
        );

  @override
  void onKill(Player player, Vector2 enemyPosition) {
    if (!player.hasTriggeredExplosionRecently()) {
      // ✅ Prevent excessive explosions
      player.triggerExplosion(enemyPosition);
    }
  }
}

// ✅ Add cooldown tracking to prevent multiple explosions at once
extension ExplosionCooldown on Player {
  bool hasTriggeredExplosionRecently() {
    double currentTime = gameRef.currentTime();

    if (currentTime - lastExplosionTime < Player.explosionCooldown) {
      // ✅ Correct usage of static field
      return true; // ✅ Prevent excessive explosions
    }

    lastExplosionTime = currentTime;
    return false;
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
