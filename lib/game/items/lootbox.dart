import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'dart:math';

class LootBox extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final List<Item> items;
  bool isOpened = false; // Prevent multiple openings

  // Add these properties for sparks
  final _random = Random();
  final List<Vector2> _sparkPositions = [];
  final List<double> _sparkTimers = [];
  static const int _maxSparks = 5;
  static const double _sparkInterval = 0.2;
  double _timeSinceLastSpark = 0;

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

    // Update sparks
    for (int i = _sparkTimers.length - 1; i >= 0; i--) {
      _sparkTimers[i] -= dt;
      if (_sparkTimers[i] <= 0) {
        _sparkTimers.removeAt(i);
        _sparkPositions.removeAt(i);
      }
    }

    // Add new sparks
    _timeSinceLastSpark += dt;
    if (_timeSinceLastSpark >= _sparkInterval &&
        _sparkPositions.length < _maxSparks) {
      _timeSinceLastSpark = 0;
      _addSpark();
    }

    final player = gameRef.player;
    final distance = (player.position - position).length;

    if (distance < 50) {
      // ✅ Increased interaction range
      _openLootBox();
    }
  }

  void _addSpark() {
    _sparkPositions.add(Vector2(
      _random.nextDouble() * size.x,
      _random.nextDouble() * size.y,
    ));
    _sparkTimers.add(0.5); // Spark duration
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render sparks
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _sparkPositions.length; i++) {
      final sparkPos = _sparkPositions[i];
      final progress = _sparkTimers[i] / 0.5; // normalize to 0-1
      final sparkSize = 3.0 * progress;

      canvas.drawCircle(
        Offset(sparkPos.x, sparkPos.y),
        sparkSize,
        paint,
      );
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
