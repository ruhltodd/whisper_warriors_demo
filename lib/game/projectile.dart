import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'enemy.dart';
import 'wave2Enemy.dart';
import 'main.dart';

class Projectile extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;
  final double maxRange; // 🔹 Max travel distance before disappearing
  late Vector2 spawnPosition; // 🔹 Track where it was fired

  Projectile({required this.damage, this.maxRange = 200}) // 🔹 De
      : super(size: Vector2(50, 50)); // Adjust size as needed

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite from assets
    sprite = await gameRef.loadSprite('projectile_normal.png');

    // Add a circular hitbox for collision
    add(CircleHitbox()..debugMode = false); // Disable debug visuals
    spawnPosition = position.clone(); // 🔹 Store initial position
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the projectile
    position += velocity * dt;

    // 🔹 Remove projectile if it exceeds max range
    if ((position - spawnPosition).length > maxRange) {
      removeFromParent();
      return;
    }
    // 🔹 Remove projectile if it goes off-screen
    if (position.y < 0 ||
        position.y > gameRef.size.y ||
        position.x < 0 ||
        position.x > gameRef.size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BaseEnemy) {
      other.takeDamage(damage); // ✅ Now correctly recognized as an Enemy
      removeFromParent();
    } else if (other is Wave2Enemy) {
      other.takeDamage(damage); // ✅ Now correctly recognized as an Enemy2
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
