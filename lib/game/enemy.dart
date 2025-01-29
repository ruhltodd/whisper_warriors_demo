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
  int health = 3;
  VoidCallback? onRemoveCallback; // Add callback for removal

  Enemy(this.player)
      : super(
          size: Vector2(32, 32), // Match the sprite size
          anchor: Anchor.center, // Center the sprite
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite sheet
    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('mob1.png'), // The sprite sheet file
      srcSize: Vector2(32, 32), // Size of each frame in the sprite sheet
    );

    // Create a walking animation
    animation = spriteSheet.createAnimation(
      row: 0, // Assuming the walking frames are in the first row
      stepTime: 0.2, // Duration of each frame in seconds
      to: 2, // Number of frames in the animation
    );

    // Add a collision hitbox
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move toward the player
    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    // Damage the player if too close
    if ((player.position - position).length < 10) {
      player.takeDamage(1); // Deal 1 damage to the player
      removeFromParent(); // Remove the enemy after dealing damage
    }
  }

  void takeDamage(int damage) {
    health -= damage;

    // Spawn damage number
    final damageNumber = DamageNumber(
        damage,
        position.clone() +
            Vector2(0, -10)); // Adjusted position above the enemy
    gameRef.add(damageNumber);

    if (health <= 0) {
      // Drop an experience item
      final drop = DropItem(expValue: 10)..position = position.clone();
      gameRef.add(drop);

      removeFromParent(); // Remove the enemy when health is depleted
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    onRemoveCallback?.call(); // Trigger the callback on removal
  }
}
