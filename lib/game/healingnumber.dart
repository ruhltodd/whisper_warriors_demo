import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealingNumber extends TextComponent with HasGameRef {
  final int amount;
  double lifetime = 1.0; // ✅ Controls fade-out duration

  HealingNumber(this.amount, Vector2 position)
      : super(
          text: "+$amount HP",
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 20 * dt; // ✅ Float upwards
    lifetime -= dt; // ✅ Reduce lifetime

    // ✅ Adjust opacity dynamically
    final opacity = lifetime.clamp(0.0, 1.0);
    textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.green.withOpacity(opacity),
      ),
    );

    if (lifetime <= 0) {
      removeFromParent(); // ✅ Remove when faded out
    }
  }
}
