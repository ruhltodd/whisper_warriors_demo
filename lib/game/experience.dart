import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class ExperienceBar extends PositionComponent
    with HasGameRef<RogueShooterGame> {
  final double barWidth = 200; // Width of the experience bar
  final double barHeight = 10; // Height of the experience bar
  double currentExp = 0;
  double expToLevel = 100;
  int playerLevel = 1;

  ExperienceBar() {
    width = barWidth;
    height = barHeight;
  }

  void updateExperience(int exp, int expToNextLevel, int level) {
    currentExp = exp.toDouble();
    expToLevel = expToNextLevel.toDouble();
    playerLevel = level;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the full bar background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, barWidth, barHeight),
      Paint()..color = const Color(0xFF444444),
    );

    // Draw the filled portion
    final filledWidth = (currentExp / expToLevel) * barWidth;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, filledWidth, barHeight),
      Paint()..color = const Color(0xFF00FF00), // Green for experience
    );

    // Draw the player level text
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.render(canvas, 'Level: $playerLevel', Vector2(5, -20));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Position the experience bar at the top-left corner of the screen
    position = Vector2(10, 50); // A fixed position with padding
  }
}
