import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class DamageNumber extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Vector2 initialPosition;
  final int damage;
  double timer = 1.0; // Display time in seconds
  late List<SpriteComponent> digitSprites = [];

  static final Map<int, Sprite> numberSprites = {}; // Store loaded sprites

  DamageNumber(this.damage, this.initialPosition) {
    position = initialPosition;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;

    await _loadSpritesIfNeeded();

    _createDamageNumberSprites();
  }

  /// Loads sprites into a map if they haven't been loaded yet
  Future<void> _loadSpritesIfNeeded() async {
    if (numberSprites.isEmpty) {
      for (int i = 0; i <= 9; i++) {
        numberSprites[i] = await gameRef.loadSprite('$i.png');
      }
    }
  }

  /// Creates and positions sprite digits
  void _createDamageNumberSprites() {
    String damageString = damage.toString();
    double offsetX = 0;

    for (int i = 0; i < damageString.length; i++) {
      int digit = int.parse(damageString[i]);

      SpriteComponent digitSprite = SpriteComponent(
        sprite: numberSprites[digit],
        size: Vector2(16, 16), // Adjust size as needed
        position: Vector2(offsetX, 0),
        anchor: Anchor.center,
      );

      digitSprites.add(digitSprite);
      add(digitSprite);

      offsetX += 12; // Adjust spacing between numbers
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += Vector2(0, -20 * dt); // Move upward
    timer -= dt;

    if (timer <= 0) {
      removeFromParent();
    }
  }
}
