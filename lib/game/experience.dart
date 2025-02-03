import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class SpiritBar extends PositionComponent with HasGameRef<RogueShooterGame> {
  final double barWidth = 200;
  final double barHeight = 10;

  double spiritExp = 0.0;
  double spiritExpToNextLevel = 1000.0;
  int spiritLevel = 1;

  /// ✅ **New Notifier for UI updates**
  final ValueNotifier<double> spiritExpNotifier = ValueNotifier<double>(0.0);

  SpiritBar() {
    width = barWidth;
    height = barHeight;
  }

  void updateSpirit(double spirit, double spiritToNextLevel, int level) {
    spiritExp = spirit;
    spiritExpToNextLevel = spiritToNextLevel;
    spiritLevel = level;

    /// ✅ Notify UI that Spirit EXP has changed!
    spiritExpNotifier.value = spiritExp;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = Vector2(10, 50);
  }
}
