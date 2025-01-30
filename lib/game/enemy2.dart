import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'player.dart';
import 'main.dart';
import 'damagenumber.dart';
import 'dropitem.dart';
import 'package:flutter/foundation.dart';
import 'enemy.dart';

class Enemy2 extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  double speed = 50; // Slower than Enemy
  int health = 6; // More health
  VoidCallback? onRemoveCallback;

  Enemy2(this.player)
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('mob2.png'),
      srcSize: Vector2(32, 32),
    );

    animation = spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.2,
      to: 2,
    );

    // **✅ Add Hitbox for Collision**
    add(RectangleHitbox(isSolid: false)); // Make sure projectiles can hit
  }

  @override
  void update(double dt) {
    super.update(dt);

    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    if ((player.position - position).length < 10) {
      player.takeDamage(1);
      removeFromParent();
    }
  }

  void takeDamage(int damage) {
    health -= damage;

    final damageNumber =
        DamageNumber(damage, position.clone() + Vector2(0, -10));
    gameRef.add(damageNumber);

    if (health <= 0) {
      // **✅ Drop Coins (Exp) on Death**
      final drop = DropItem(expValue: 20)..position = position.clone();
      gameRef.add(drop);

      if (gameRef.player.vampiricHealing > 0) {
        gameRef.player.gainHealth(gameRef.player.vampiricHealing.toInt());
      }

      removeFromParent();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    onRemoveCallback?.call();
  }
}
