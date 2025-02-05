import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'enemy.dart';
import 'wave2Enemy.dart';
import 'player.dart';
import 'main.dart';

class Projectile extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;
  final bool isBossProjectile;
  final double maxRange;
  late Vector2 spawnPosition;

  // 🔹 **General Constructor**
  Projectile({
    required this.damage,
    required this.velocity,
    this.isBossProjectile = false,
    this.maxRange = 800, // ✅ Default range for player projectiles
  }) : super(size: Vector2(50, 50)); // Adjust size as needed

  // 🔹 **Named Constructor for Player**
  Projectile.playerProjectile({required int damage, required Vector2 velocity})
      : this(
          damage: damage,
          velocity: velocity,
          maxRange: 800,
          isBossProjectile: false,
        );

  // 🔹 **Named Constructor for Boss**
  Projectile.bossProjectile({required int damage, required Vector2 velocity})
      : this(
          damage: damage,
          velocity: velocity,
          maxRange: double.infinity, // ✅ Boss projectiles should go forever
          isBossProjectile: true,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    spawnPosition = position.clone(); // ✅ Track initial position

    if (isBossProjectile) {
      final spriteSheet = await gameRef.images.load('boss_projectile.png');

      // ✅ Assign animation
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4, // ✅ Number of frames
          stepTime: 0.3, // ✅ Adjust animation speed
          textureSize: Vector2(80, 80), // ✅ Each frame size
          loop: true, // ✅ Keeps looping while projectile is active
        ),
      );
    } else {
      final normalSprite = await gameRef.loadSprite('projectile_normal.png');

      // ✅ Single-frame animation for normal projectiles
      animation = SpriteAnimation.spriteList(
        [normalSprite],
        stepTime: double.infinity, // ✅ Static sprite, never loops
      );
    }

    add(CircleHitbox()); // ✅ Ensure hitbox exists
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // 🔹 **Remove player projectiles after max range**
    if (!isBossProjectile && (position - spawnPosition).length > maxRange) {
      removeFromParent(); // ✅ Ensures only the projectile is removed
    }

    // 🔹 **Boss Projectiles travel indefinitely**
    if (isBossProjectile &&
        (position.x < -500 ||
            position.x > gameRef.size.x + 500 ||
            position.y < -500 ||
            position.y > gameRef.size.y + 500)) {
      // ✅ Ensure only the projectile is removed, not the boss
      if (this is Projectile) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isBossProjectile) {
      if (other is BaseEnemy) {
        other.takeDamage(damage);
        removeFromParent();
      } else if (other is Wave2Enemy) {
        other.takeDamage(damage);
        removeFromParent();
      }
    } else {
      if (other is Player) {
        other.takeDamage(damage);
        removeFromParent();
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
