import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class HealthBar extends PositionComponent {
  final Player player;
  final double barWidth = 50; // Fixed width of the health bar
  final double barHeight = 5; // Fixed height of the health bar
  late Paint greenPaint;
  late Paint redPaint;

  HealthBar(this.player) {
    greenPaint = Paint()..color = const Color(0xFF00FF00); // Green for health
    redPaint = Paint()
      ..color = const Color(0xFFFF0000); // Red for missing health
    size = Vector2(barWidth, barHeight);
  }

  void updateHealth(int currentHealth, int maxHealth) {
    final healthPercentage = currentHealth / maxHealth;
    size = Vector2(barWidth * healthPercentage, barHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Calculate the position relative to the player's sprite anchor

    // Center the health bar above the player's head and shift it to the right
    const double xOffset = 0;
    30; // Adjust this value to move the bar further right
    const double yOffset = 10; // Adjust this value to move the bar up or down

    position = player.position.clone() -
        Vector2(barWidth / 2, player.size.y / 2 + yOffset) +
        Vector2(xOffset, 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the red background
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), redPaint);

    // Draw the green health bar
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, barHeight), greenPaint);
  }
}
