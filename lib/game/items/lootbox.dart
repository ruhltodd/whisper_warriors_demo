import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'package:whisper_warriors/game/ui/notifications.dart';
import 'package:whisper_warriors/game/items/items.dart';

class LootBox extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final List<Item> items;
  bool isOpened = false; // Prevent multiple openings

  LootBox({required this.items}) : super(size: Vector2(30, 30)) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('lootbox.png');
    print("🗃️ LootBox loaded with sprite: assets/images/lootbox.png");

    // ✅ Start the bounce effect when spawned
    _playBounceEffect();
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

    if (isOpened) return;

    final player = gameRef.player;
    final distance = (player.position - position).length;

    if (distance < 50) {
      // ✅ Increased interaction range
      _openLootBox();
    }
  }

  void _openLootBox() {
    isOpened = true;
    print("🗃️ LootBox opened at position: $position");

    for (var item in items) {
      final dropItem = DropItem(item: item);
      dropItem.position = position.clone();
      gameRef.add(dropItem);
      print(
          "💰 Item spawned from LootBox: ${item.spriteName} at ${dropItem.position}");

      // ✅ Send loot info to the Loot Notification Bar (HUD)
      gameRef.lootNotificationBar
          .addLootNotification(item.name, item.rarity, 1);
    }

    removeFromParent(); // ✅ Remove loot box after opening
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isOpened) {
      _openLootBox();
    }
    super.onCollision(intersectionPoints, other);
  }
}
