import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'enemy.dart';
import 'wave2Enemy.dart';
import 'player.dart';
import 'main.dart';

class Projectile extends SpriteComponent
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
      print("🎯 Boss Projectile Spawned at $position");
      sprite = await gameRef.loadSprite('boss_projectile.png');
    } else {
      sprite = await gameRef.loadSprite('projectile_normal.png');
    }

    add(CircleHitbox()); // ✅ Ensure hitbox exists
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    print("🔹 Projectile moving to ${position}");

    // 🔹 **Remove player projectiles after max range**
    if (!isBossProjectile && (position - spawnPosition).length > maxRange) {
      print("❌ Player Projectile removed - Max range reached!");
      removeFromParent();
    }

    // 🔹 **Boss Projectiles travel indefinitely**
    if (isBossProjectile &&
        (position.x < -500 ||
            position.x > gameRef.size.x + 500 ||
            position.y < -500 ||
            position.y > gameRef.size.y + 500)) {
      print("❌ Boss Projectile removed - Off-screen!");
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isBossProjectile) {
      if (other is BaseEnemy) {
        print("💥 Player Projectile hit Enemy!");
        other.takeDamage(damage);
        removeFromParent();
      } else if (other is Wave2Enemy) {
        print("💥 Player Projectile hit Wave2 Enemy!");
        other.takeDamage(damage);
        removeFromParent();
      }
    } else {
      if (other is Player) {
        print("💥 Boss Projectile hit PLAYER!");
        other.takeDamage(damage);
        removeFromParent();
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
