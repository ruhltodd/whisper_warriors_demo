import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class HealthBar extends PositionComponent {
  final Player player;
  final double barWidth = 50; // Fixed width
  final double barHeight = 6; // Slightly taller for better visibility
  double healthPercentage = 1.0; // Start full

  HealthBar(this.player) {
    size = Vector2(barWidth, barHeight);
  }

  void updateHealth(int currentHealth, int maxHealth) {
    healthPercentage = (currentHealth / maxHealth).clamp(0.0, 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ Keep health bar above the player
    const double yOffset = 12; // Adjust height positioning
    position = player.position.clone() -
        Vector2(barWidth / 2, player.size.y / 2 + yOffset);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // ✅ Transparent background (no red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, barWidth, barHeight),
        Radius.circular(4),
      ),
      Paint()..color = Colors.transparent, // No background
    );

    // ✅ Choose solid color based on health thresholds
    Color healthColor;
    if (healthPercentage > 0.75) {
      healthColor = Colors.green; // 75% - 100%
    } else if (healthPercentage > 0.5) {
      healthColor = Color.lerp(
          Colors.green, Colors.orange, (healthPercentage - 0.5) * 4)!;
    } else if (healthPercentage > 0.25) {
      healthColor =
          Color.lerp(Colors.orange, Colors.red, (healthPercentage - 0.25) * 4)!;
    } else {
      healthColor = Colors.red; // 0% - 25%
    }

    // ✅ Draw rounded health bar with dynamic color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, barWidth * healthPercentage, barHeight),
        Radius.circular(4),
      ),
      Paint()..color = healthColor,
    );
  }
}
