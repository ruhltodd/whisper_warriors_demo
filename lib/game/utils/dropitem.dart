import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/items/items.dart';

class DropItem extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final Item item;
  bool isCollected = false; // Prevent duplicate pickups
  bool canBeCollected = false; // Delay before item can be collected

  DropItem({required this.item}) : super(size: Vector2(15, 15)) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite(item.spriteName);

    // ✅ Start the bounce effect when spawned
    _playBounceEffect();

    // Delay before the item can be collected
    Future.delayed(Duration(seconds: 1), () {
      canBeCollected = true;
    });
  }

  void _playBounceEffect() {
    final originalY = position.y;

    // Pop up a little, then come back down before floating to the player
    add(
      MoveByEffect(
        Vector2(0, -10), // Move up by 10 pixels
        EffectController(duration: 0.2, curve: Curves.easeOut),
        onComplete: () {
          add(
            MoveByEffect(
              Vector2(0, 10), // Move back down
              EffectController(duration: 0.2, curve: Curves.easeIn),
            ),
          );
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isCollected || !canBeCollected) return;

    final player = gameRef.player;
    final distance = (player.position - position).length;

    if (distance < 50) {
      // ✅ Increased pickup range
      _moveToPlayer();
    }
  }

  void _moveToPlayer() {
    isCollected = true; // Prevent multiple pickups

    add(
      MoveToEffect(
        gameRef.player.position, // Move towards the player
        EffectController(duration: 0.3, curve: Curves.easeOut),
        onComplete: () {
          gameRef.player.gainSpiritExp(item.expValue.toDouble()); // ✅ Give EXP
          removeFromParent(); // ✅ Remove item after collection
          print("💰 Player collected ${item.expValue} EXP from ${item.name}!");
        },
      ),
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isCollected && canBeCollected) {
      _moveToPlayer();
    }
    super.onCollision(intersectionPoints, other);
  }
}
