import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class StaggerBar extends PositionComponent {
  final double maxStagger;
  double currentStagger = 0;

  StaggerBar({required this.maxStagger}) : super(size: Vector2(100, 8));

  void updateStagger(double staggerAmount) {
    currentStagger = staggerAmount.clamp(0, maxStagger);
  }

  void resetStagger() {
    currentStagger = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Background Bar
    Paint backgroundPaint = Paint()..color = const Color(0xFF444444);
    canvas.drawRect(size.toRect(), backgroundPaint);

    // Fill Bar
    if (currentStagger > 0) {
      Paint fillPaint = Paint()..color = const Color(0xFFFFD700); // Gold color
      double barWidth = (currentStagger / maxStagger) * size.x;
      canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, size.y), fillPaint);
    }
  }
}
