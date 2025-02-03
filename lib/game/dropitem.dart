import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'player.dart';
import 'main.dart';

class DropItem extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final int expValue;

  DropItem({required this.expValue}) : super(size: Vector2(15, 15)) {
    add(CircleHitbox()); // Add a hitbox for collision
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite for the coin
    sprite =
        await gameRef.loadSprite('blue_coin.png'); // Ensure this file exists
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.gainSpiritExp(expValue.toDouble()); // ✅ Updated to Spirit EXP
      removeFromParent(); // Remove the drop after collection
    }
    super.onCollision(intersectionPoints, other);
  }
}
