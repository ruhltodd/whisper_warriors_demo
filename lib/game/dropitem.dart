import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'player.dart';
import 'main.dart';

class DropItem extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final int expValue;
  final String spriteName; // ✅ Fix: Ensure spriteName is stored

  DropItem({required this.expValue, required this.spriteName})
      : super(size: Vector2(15, 15)) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // ✅ Fix: Load correct sprite based on `spriteName`
    sprite = await gameRef.loadSprite(spriteName);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.gainSpiritExp(expValue.toDouble()); // ✅ Grants Spirit EXP
      removeFromParent(); // ✅ Remove item after pickup
      print("💰 Player collected $expValue EXP from $spriteName!");
    }
    super.onCollision(intersectionPoints, other);
  }
}
