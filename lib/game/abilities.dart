import 'dart:math';
import 'package:flame/components.dart';
import 'player.dart';
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
  double cooldown = 2.0; // Cooldown between throws
  double elapsedTime = 0.0;

  ShadowBlades()
      : super(
          name: "Shadow Blades",
          description: "Throws spectral blades that pierce through enemies.",
          type: AbilityType.projectile,
        );

  @override
  void applyEffect(Player player) {
    super.applyEffect(player);
  }

  @override
  void onUpdate(Player player, double dt) {
    elapsedTime += dt;
    if (elapsedTime >= cooldown) {
      elapsedTime = 0.0; // ✅ Reset cooldown
      _throwBlades(player);
    }
  }

  void _throwBlades(Player player) {
    print("🗡️ Throwing Shadow Blades!");

    int bladeCount = 3; // Number of blades
    double spreadAngle = 15.0 * (pi / 180); // ✅ Convert degrees to radians

    for (int i = 0; i < bladeCount; i++) {
      double angleOffset = (i - 1) * spreadAngle;
      Vector2 direction = Vector2(1, 0)..rotate(player.angle + angleOffset);

      final blade = ShadowBladeProjectile(
        damage: (10 * player.spiritMultiplier).toInt(),
        velocity: direction *
            (500 + (player.spiritLevel * 50)), // ✅ Scales with Spirit Level
        player: player,
      )
        ..position = player.position.clone()
        ..size = Vector2(48, 16) // Blade sprite size
        ..anchor = Anchor.center;

      player.gameRef.add(blade);
    }
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
