import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/main.dart';

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
class WhisperingFlames extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>
    implements Ability {
  double baseDamagePerSecond = 3.0; // Base damage per second
  double range = 150.0; // Range in which enemies take damage
  double _elapsedTime = 0.0; // Timer for damage ticks

  final String name = "Whispering Flames";
  final String description = "A fire aura that burns enemies near you.";
  final AbilityType type = AbilityType.aura;

  WhisperingFlames() : super(size: Vector2(100, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final spriteSheet = await gameRef.loadSprite('fire_aura.png');
    final spriteSize = Vector2(100, 100);
    final frameCount = 3;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: 0.1,
        textureSize: spriteSize,
      ),
    );

    add(CircleHitbox(
      radius: range,
      position: size / 2,
      anchor: Anchor.center,
    )..collisionType = CollisionType.passive);
  }

  @override
  void applyEffect(Player player) {
    position = player.position.clone();
  }

  @override
  void onUpdate(Player player, double dt) {
    // This method is required by the Ability interface
    // The actual update logic is handled in the Component's update method
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef == null) return;

    // Update aura position to follow player
    final player = gameRef.player;
    if (player != null) {
      position = player.position.clone();
    }

    _elapsedTime += dt;

    if (_elapsedTime >= 1.0) {
      _elapsedTime = 0.0; // Reset timer
      double scaledDamage = baseDamagePerSecond * player.spiritMultiplier;

      // Damage all enemies within range
      for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
        double distance = (enemy.position - position).length;
        if (distance < range) {
          bool isCritical =
              gameRef.random.nextDouble() < player.critChance / 100;
          int finalDamage = isCritical
              ? (scaledDamage * player.critMultiplier).toInt()
              : scaledDamage.toInt();

          enemy.takeDamage(finalDamage, isCritical: isCritical);
        }
      }
    }
  }

  @override
  void onKill(Player player, Vector2 enemyPosition) {}

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {}
}

/// 🗡️ **Shadow Blades Ability Controller**
class ShadowBladesAbility extends Ability {
  double cooldown = 0.5; // Time between blade throws
  double elapsedTime = 0.0;

  ShadowBladesAbility()
      : super(
          name: "Shadow Blades",
          description: "Throws a spectral blade at the closest enemy.",
          type: AbilityType.projectile,
        );

  void _spawnBlade(Player player) {
    BaseEnemy? target = _findClosestTarget(player);
    if (target == null) return;

    Vector2 direction = (target.position - player.position).normalized();
    double rotationAngle = direction.angleTo(Vector2(1, 0));

    final blade = ShadowBladeProjectile(
      player: player,
      damage: (12 * player.spiritMultiplier).toInt(),
      velocity: direction * 750,
      rotationAngle: rotationAngle,
    )..position = player.position.clone();

    player.gameRef.add(blade);

    // Roll Cursed Echo ONCE per blade thrown
    if (player.hasAbility<CursedEcho>() &&
        player.gameRef.random.nextDouble() < 0.20) {
      print("🔄 Cursed Echo triggered for Shadow Blade!");
      Future.delayed(Duration(milliseconds: 100), () {
        player.gameRef.add(ShadowBladeProjectile(
          player: player,
          damage: (12 * player.spiritMultiplier).toInt(),
          velocity: direction * 750,
          rotationAngle: rotationAngle,
        )..position = player.position.clone());
      });
    }
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

  @override
  void onUpdate(Player player, double dt) {
    elapsedTime += dt;
    if (elapsedTime >= cooldown) {
      elapsedTime = 0.0;
      _spawnBlade(player);
    }
  }
}

/// 🗡️ **Shadow Blade Projectile Component**
class ShadowBladeProjectile extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final double bladeSpeed = 750;
  double maxDistance = 1200;
  Vector2 startPosition = Vector2.zero();
  final Vector2 velocity;
  final double rotationAngle;
  final int damage;

  ShadowBladeProjectile({
    required this.player,
    required this.velocity,
    required this.rotationAngle,
    required this.damage,
  }) : super(size: Vector2(48, 16), anchor: Anchor.center) {
    angle = rotationAngle;
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      await gameRef.images.load('shadowblades.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2(48, 16),
        loop: true,
      ),
    );
    startPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if ((position - startPosition).length >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BaseEnemy) {
      bool isCritical = gameRef.random.nextDouble() < (player.critChance / 100);
      int finalDamage =
          isCritical ? (damage * player.critMultiplier).toInt() : damage;

      other.takeDamage(finalDamage, isCritical: isCritical);
    } else if (other is Projectile && other is! ShadowBladeProjectile) {
      return;
    }

    super.onCollision(intersectionPoints, other);
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
