import 'dart:math';
import 'package:flame/components.dart';
import 'player.dart';
import 'main.dart';
import 'enemy.dart';
import 'fireaura.dart';
import 'explosion.dart';
import 'shadowblades.dart'; // ✅ Import the Shadow Blade effect

/// Enum for ability types (optional, for categorization)
enum AbilityType { passive, onHit, onKill, aura, scaling, projectile }

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
  double baseDamagePerSecond = 3.0; // 🔥 Base value (scaled by Spirit)
  double range = 200.0;
  double _elapsedTime = 0.0;

  double get damage => baseDamagePerSecond; // ✅ Add damage getter

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

    _elapsedTime += dt; // ✅ Accumulate time

    if (_elapsedTime >= 1.0) {
      _elapsedTime = 0.0; // ✅ Reset timer

      double scaledDamage = baseDamagePerSecond * player.spiritMultiplier;

      for (var enemy in player.gameRef.children.whereType<BaseEnemy>()) {
        double distance = (enemy.position - player.position).length;

        if (distance < range) {
          bool isCritical =
              player.gameRef.random.nextDouble() < player.critChance / 100;
          int finalDamage = isCritical
              ? (scaledDamage * player.critMultiplier).toInt()
              : scaledDamage.toInt();

          enemy.takeDamage(finalDamage, isCritical: isCritical);
        }
      }
    }
  }
}

/// 💀 **Shadow Blades Ability**

class ShadowBlades extends Ability {
  double cooldown = 0.5; // ✅ Faster attack speed
  double elapsedTime = 0.0;

  ShadowBlades()
      : super(
          name: "Shadow Blades",
          description:
              "Auto-targets and throws a spectral blade at the closest enemy.",
          type: AbilityType.projectile,
        );

  @override
  void onUpdate(Player player, double dt) {
    elapsedTime += dt;
    if (elapsedTime >= cooldown) {
      elapsedTime = 0.0; // ✅ Reset cooldown
      _throwBlade(player);
    }
  }

  void _throwBlade(Player player) {
    print("🗡️ Throwing Shadow Blade!");

    // ✅ Find the closest enemy or boss
    BaseEnemy? target = _findClosestTarget(player);

    if (target == null) {
      print("⚠️ No enemies found - Shadow Blade not fired.");
      return;
    }

    // ✅ Direction towards the enemy
    Vector2 direction = (target.position - player.position).normalized();
    double rotationAngle = direction.angleTo(Vector2(1, 0));

    final blade = ShadowBladeProjectile(
      damage: (12 * player.spiritMultiplier).toInt(),
      velocity: direction *
          (750 + (player.spiritLevel * 20)), // ✅ Scales speed with Spirit Level
      player: player,
      rotationAngle: rotationAngle,
    )
      ..position = player.position.clone()
      ..size = Vector2(48, 16)
      ..anchor = Anchor.center;

    player.gameRef.add(blade);
  }

  BaseEnemy? _findClosestTarget(Player player) {
    final enemies = player.gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) return null;

    BaseEnemy? closest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
      double distance = (enemy.position - player.position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = enemy;
      }
    }
    return closest;
  }
}

/// 💀 **Soul Fracture Ability**
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
