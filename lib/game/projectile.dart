import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'enemy.dart';
import 'main.dart';

class Projectile extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;

  Projectile({required this.damage})
      : super(size: Vector2(16, 16)); // Adjust size as needed

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite from assets
    sprite = await gameRef.loadSprite('projectile_normal.png');

    // Add a circular hitbox for collision
    add(CircleHitbox()..debugMode = false); // Disable debug visuals
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the projectile
    position += velocity * dt;

    // Remove projectile if it goes off-screen
    if (position.y < 0 ||
        position.y > gameRef.size.y ||
        position.x < 0 ||
        position.x > gameRef.size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      other.takeDamage(damage); // Deal damage to the enemy
      removeFromParent(); // Destroy projectile after collision
    }
    super.onCollision(intersectionPoints, other);
  }
}
