import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class DamageNumber extends TextComponent with HasGameRef<RogueShooterGame> {
  final Vector2 initialPosition;
  final int damage;
  double timer = 1.0; // Display time in seconds

  DamageNumber(this.damage, this.initialPosition)
      : super(
          text: '-$damage',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ) {
    position = initialPosition;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center; // Ensure the text is centered at its position
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the damage number upward and reduce its opacity over time
    position += Vector2(0, -20 * dt); // Move upward
    timer -= dt;
    if (timer <= 0) {
      removeFromParent(); // Remove after time expires
    }
  }
}
