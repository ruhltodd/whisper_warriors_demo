import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';

class SpiritBar extends PositionComponent with HasGameRef<RogueShooterGame> {
  final double barWidth = 200;
  final double barHeight = 10;

  double spiritExp = 0.0;
  double spiritExpToNextLevel = 500.0;
  int spiritLevel = 1;

  // Add notifiers
  late final ValueNotifier<double> _spiritExpNotifier;
  late final ValueNotifier<int> _spiritLevelNotifier;
  bool _isDisposed = false;

  SpiritBar() {
    width = barWidth;
    height = barHeight;

    _spiritExpNotifier = PlayerProgressManager.spiritExpNotifier;
    _spiritLevelNotifier = PlayerProgressManager.spiritLevelNotifier;

    // Add listeners
    _spiritExpNotifier.addListener(_updateSpirit);
    _spiritLevelNotifier.addListener(_updateSpirit);
  }

  void _updateSpirit() {
    if (!_isDisposed) {
      spiritExp = _spiritExpNotifier.value * spiritExpToNextLevel;
      spiritLevel = _spiritLevelNotifier.value;
    }
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }

  void dispose() {
    if (!_isDisposed) {
      try {
        _spiritExpNotifier.removeListener(_updateSpirit);
        _spiritLevelNotifier.removeListener(_updateSpirit);
        _isDisposed = true;
        print('🌟 SpiritBarLevel disposed safely');
      } catch (e) {
        print('⚠️ Warning: Error disposing SpiritBarLevel: $e');
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = Vector2(10, 50);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), bgPaint);

    // Draw progress
    final progressPaint = Paint()
      ..color = Colors.purple.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final progress = (spiritExp / spiritExpToNextLevel).clamp(0.0, 1.0);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, barWidth * progress, barHeight), progressPaint);

    // Draw level text
    final textSpan = TextSpan(
      text: 'Spirit Level $spiritLevel',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(0, -20));
  }
}
