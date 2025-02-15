import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class ShadowEffect {
  static Paint createEtherealShadow({
    Color shadowColor = const Color.fromRGBO(70, 130, 180, 0.4),
    double contrast = 1.2,
    double brightness = 0.1,
  }) {
    return Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: 0, sigmaY: 0)
      ..colorFilter = ColorFilter.mode(
        shadowColor,
        BlendMode.srcATop,
      );
  }

  static void renderWithShadow(
    Canvas canvas,
    SpriteAnimationComponent component, {
    bool isEnemy = false,
    bool isBoss = false,
  }) {
    final Paint originalPaint = component.paint;
    final originalRender = () => component.renderTree(canvas);

    // First shadow layer (larger, softer)
    canvas.save();
    if (isBoss) {
      canvas.translate(6, 6);
      component.paint.imageFilter = ImageFilter.blur(sigmaX: 6, sigmaY: 6);
    } else {
      canvas.translate(4, 4);
      component.paint.imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    }
    originalRender();
    canvas.restore();

    // Second shadow layer (smaller, sharper)
    canvas.save();
    canvas.translate(2, 2);
    component.paint.imageFilter = ImageFilter.blur(sigmaX: 2, sigmaY: 2);
    originalRender();
    canvas.restore();

    // Main sprite with contrast
    component.paint.imageFilter = null;
    component.paint.colorFilter = ColorFilter.matrix([
      1.2,
      0,
      0,
      0,
      0.1,
      0,
      1.2,
      0,
      0,
      0.1,
      0,
      0,
      1.2,
      0,
      0.1,
      0,
      0,
      0,
      1,
      0,
    ]);
    originalRender();
  }
}

mixin ShadowEffectMixin on SpriteAnimationComponent {
  void renderWithShadow(Canvas canvas) {
    // First shadow layer (larger, softer)
    canvas.save();
    paint.imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    canvas.translate(4, 4);
    super.render(canvas);
    canvas.restore();

    // Second shadow layer (smaller, sharper)
    canvas.save();
    paint.imageFilter = ImageFilter.blur(sigmaX: 2, sigmaY: 2);
    canvas.translate(2, 2);
    super.render(canvas);
    canvas.restore();

    // Main sprite
    paint.imageFilter = null;
    paint.colorFilter = ColorFilter.matrix([
      1.2,
      0,
      0,
      0,
      0.1,
      0,
      1.2,
      0,
      0,
      0.1,
      0,
      0,
      1.2,
      0,
      0.1,
      0,
      0,
      0,
      1,
      0,
    ]);
    super.render(canvas);
  }
}
