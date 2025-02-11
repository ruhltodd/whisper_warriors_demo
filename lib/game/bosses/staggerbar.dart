import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/src/widgets/framework.dart';

class StaggerBar extends PositionComponent {
  final double maxStagger;
  double currentStagger;

  // Constructor accepts both the maxStagger and initial staggerValue
  StaggerBar({required this.maxStagger, required this.currentStagger})
      : super(size: Vector2(100, 8));

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

    // Fill Bar - Represents the current stagger value
    if (currentStagger > 0) {
      Paint fillPaint = Paint()..color = const Color(0xFFFFD700); // Gold color
      double barWidth = (currentStagger / maxStagger) *
          size.x; // Scale the width based on stagger
      canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, size.y), fillPaint);
    }
  }

  build(BuildContext context) {}
}
