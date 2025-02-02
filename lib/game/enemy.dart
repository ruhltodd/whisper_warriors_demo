import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart'; // Import for VoidCallback
import 'player.dart';
import 'main.dart';
import 'damagenumber.dart';
import 'dropitem.dart';
import 'abilities.dart';
import 'explosion.dart';

class BaseEnemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final double speed;
  int health;
  VoidCallback? onRemoveCallback;

  double timeSinceLastDamageNumber = 0.0;
  final double damageNumberInterval = 0.5;

  bool hasExploded = false; // ✅ Prevent multiple explosions
  bool hasDroppedItem = false; // ✅ Prevent multiple drops

  BaseEnemy({
    required this.player,
    required this.speed,
    required this.health,
    required Vector2 size,
  }) : super(
          size: size,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastDamageNumber += dt;

    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    if ((player.position - position).length < 10) {
      player.takeDamage(1);
      removeFromParent();
    }
  }

  void takeDamage(int damage) {
    health -= damage;

    if (timeSinceLastDamageNumber >= damageNumberInterval) {
      final damageNumber =
          DamageNumber(damage, position.clone() + Vector2(0, -10));
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0.0;
    }

    if (health <= 0) {
      if (!hasExploded && gameRef.player.hasAbility<SoulFracture>()) {
        hasExploded = true;
        gameRef.add(Explosion(position)); // ✅ Add explosion animation
        gameRef.player.triggerExplosion(position);
      }

      if (!hasDroppedItem) {
        hasDroppedItem = true;
        final drop = DropItem(expValue: 10)..position = position.clone();
        gameRef.add(drop);
        gameRef.player.gainHealth(gameRef.player.vampiricHealing.toInt());
      }

      removeFromParent();
    }
  }
}
