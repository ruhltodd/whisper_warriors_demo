import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/main.dart';

class SpiritBar extends PositionComponent with HasGameRef<RogueShooterGame> {
  final double barWidth = 200;
  final double barHeight = 10;

  double spiritExp = 0.0;
  double spiritExpToNextLevel = 500.0;
  int spiritLevel = 1;

  // Bind UI updates to ProgressManager's Notifiers
  late final ValueNotifier<double> _spiritExpNotifier;
  late final ValueNotifier<int> _spiritLevelNotifier;

  SpiritBar() {
    width = barWidth;
    height = barHeight;

    // Initialize notifier references
    _spiritExpNotifier = PlayerProgressManager.spiritExpNotifier;
    _spiritLevelNotifier = PlayerProgressManager.spiritLevelNotifier;

    // Listen to XP and Level changes
    _spiritExpNotifier.addListener(() {
      updateSpirit(
          _spiritExpNotifier.value *
              PlayerProgressManager.getSpiritExpToNextLevel(),
          PlayerProgressManager.getSpiritExpToNextLevel(),
          _spiritLevelNotifier.value);
    });

    _spiritLevelNotifier.addListener(() {
      updateSpirit(spiritExp, PlayerProgressManager.getSpiritExpToNextLevel(),
          _spiritLevelNotifier.value);
    });
  }

  void updateSpirit(double spirit, double spiritToNextLevel, int level) {
    spiritExp = spirit;
    spiritExpToNextLevel = spiritToNextLevel;
    spiritLevel = level;

    print(
        "🔄 SpiritBar Updated: Level $spiritLevel | XP: ${spiritExp.toStringAsFixed(1)} / ${spiritExpToNextLevel.toStringAsFixed(1)} (${(_spiritExpNotifier.value * 100).toStringAsFixed(1)}%)");
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = Vector2(10, 50);
  }

  @override
  void onRemove() {
    super.onRemove();
    // Clean up listeners
    _spiritExpNotifier.removeListener(() {});
    _spiritLevelNotifier.removeListener(() {});
  }
}
