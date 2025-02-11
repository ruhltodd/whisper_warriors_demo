import 'package:flame/components.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/fireaura.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
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

  // Override these methods for specific ability behavior
  void applyEffect(Player player) {}
  void onKill(Player player, Vector2 enemyPosition) {}
  void onUpdate(Player player, double dt) {}
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {}
}

/// 🔥 **Whispering Flames Ability** - Fire aura that damages nearby enemies
class WhisperingFlames extends Ability {
  double baseDamagePerSecond = 3.0; // Base damage per second
  double range = 200.0; // Range in which enemies take damage
  double _elapsedTime = 0.0; // Timer for damage ticks

  WhisperingFlames()
      : super(
          name: "Whispering Flames",
          description: "A fire aura that burns enemies near you.",
          type: AbilityType.aura,
        );

  @override
  void applyEffect(Player player) {
    super.applyEffect(player);
    // Delay adding FireAura to ensure the player is fully initialized
    Future.delayed(Duration.zero, () {
      if (player.isMounted && player.gameRef != null) {
        player.gameRef.add(FireAura(player: player));
      } else {
        print("⚠️ Cannot add FireAura: player is not mounted yet.");
      }
    });
  }

  @override
  void onUpdate(Player player, double dt) {
    if (player.gameRef == null) return;
    _elapsedTime += dt;

    if (_elapsedTime >= 1.0) {
      _elapsedTime = 0.0; // Reset timer
      double scaledDamage = baseDamagePerSecond * player.spiritMultiplier;

      // Damage all enemies within range
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

/// 🗡️ **Shadow Blades Ability** - Throws auto-targeted spectral blades
class ShadowBlades extends Ability {
  double cooldown = 0.5; // Time between blade throws
  double elapsedTime = 0.0;

  ShadowBlades()
      : super(
          name: "Shadow Blades",
          description: "Throws a spectral blade at the closest enemy.",
          type: AbilityType.projectile,
        );

  @override
  void onUpdate(Player player, double dt) {
    elapsedTime += dt;
    if (elapsedTime >= cooldown) {
      elapsedTime = 0.0;
      _throwBlade(player);
    }
  }

  void _throwBlade(Player player) {
    print("🗡️ Throwing Shadow Blade!");
    BaseEnemy? target = _findClosestTarget(player);
    if (target == null) return;

    Vector2 direction = (target.position - player.position).normalized();
    double rotationAngle = direction.angleTo(Vector2(1, 0));

    final blade = ShadowBladeProjectile(
      damage: (12 * player.spiritMultiplier).toInt(),
      velocity: direction * (750 + (player.spiritLevel * 20)),
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

    return enemies.reduce((a, b) => (a.position - player.position).length <
            (b.position - player.position).length
        ? a
        : b);
  }
}

/// 🔁 **Cursed Echo Ability** - Chance to repeat attacks
class CursedEcho extends Ability {
  double baseProcChance = 0.2; // 20% base chance
  double delayBetweenRepeats = 0.2; // Delay before repeating attack
  double procCooldown = 1.0; // Cooldown to prevent excessive procs

  double _lastProcTime = 0.0;

  CursedEcho()
      : super(
          name: "Cursed Echo",
          description:
              "Every attack has a chance to repeat itself, increasing with Spirit Level.",
          type: AbilityType.onHit,
        );

  double getProcChance(Player player) {
    return (baseProcChance + (player.spiritLevel * 0.01)).clamp(0, 1);
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    double currentTime = player.gameRef.currentTime();
    if (currentTime - _lastProcTime < procCooldown)
      return; // Prevent excessive procs

    if (player.gameRef.random.nextDouble() < getProcChance(player)) {
      _lastProcTime = currentTime;
      Future.delayed(
          Duration(milliseconds: (delayBetweenRepeats * 1000).toInt()), () {
        if (target.isMounted) {
          print("🔁 Cursed Echo triggered! Repeating attack...");
          player.shootProjectile(damage, target, isCritical: isCritical);
        }
      });
    }
  }
}

/// 💥 **Soul Fracture Ability** - Enemies explode on death
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

/// 💣 **Explosion Scaling** - Scales explosion damage with Spirit Level
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
    if (hasTriggeredExplosionRecently()) return;
    gameRef.add(Explosion(position));
    print("💥 Spirit Explosion triggered!");

    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;
      if (distance < 100.0) {
        int damage = (10.0 * spiritMultiplier).toInt().clamp(1, 9999);
        enemy.takeDamage(damage);
      }
    }
  }
}
