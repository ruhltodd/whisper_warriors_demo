import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart'; // Import for VoidCallback
import 'package:flame/sprite.dart';
import 'player.dart';
import 'main.dart';
import 'damagenumber.dart';
import 'dropitem.dart';

class Enemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final double speed = 100;
  int health = 100;
  VoidCallback? onRemoveCallback;

  double timeSinceLastDamageNumber = 0.0; // ⏳ Controls visual effect timing
  final double damageNumberInterval = 0.5; // ⏳ Display every 0.5s

  Enemy(this.player)
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('mob1.png'),
      srcSize: Vector2(32, 32),
    );

    animation = spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.2,
      to: 2,
    );

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastDamageNumber += dt; // ✅ Increment damage number timer

    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    if ((player.position - position).length < 10) {
      player.takeDamage(1);
      removeFromParent();
    }
  }

  void takeDamage(int damage) {
    health -= damage;

    // ✅ Only show damage number if the interval has passed
    if (timeSinceLastDamageNumber >= damageNumberInterval) {
      final damageNumber =
          DamageNumber(damage, position.clone() + Vector2(0, -10));
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0.0; // ✅ Reset timer
    }

    if (health <= 0) {
      final drop = DropItem(expValue: 10)..position = position.clone();
      gameRef.add(drop);
      gameRef.player.gainHealth(gameRef.player.vampiricHealing.toInt());

      removeFromParent();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    onRemoveCallback?.call();
  }
}
