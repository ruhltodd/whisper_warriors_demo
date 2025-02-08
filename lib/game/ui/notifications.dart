import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';

class NotificationComponent extends TextComponent {
  final RogueShooterGame gameRef;
  final Vector2 positionOffset;
  double timer = 0.0; // Track time for removal
  double opacity = 1.0; // Track opacity for fade-out
  late TextPaint _textPaint; // Define text paint separately

  NotificationComponent(
      this.gameRef, String message, this.positionOffset, TextStyle textStyle)
      : super(
          text: message,
        ) {
    // ✅ Store textPaint separately
    _textPaint = TextPaint(style: textStyle);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set textRenderer explicitly
    textRenderer = _textPaint;

    // Get existing notifications and adjust stacking
    int existingNotifications =
        gameRef.children.whereType<NotificationComponent>().length;
    double offsetY = -40 - (existingNotifications * 20.0);

    position = gameRef.player.position.clone() + Vector2(0, offsetY);
    anchor = Anchor.center;

    print("🔔 Notification added at position: $position with message: $text");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ Ensure the notification fades out
    opacity -= dt * 0.5; // Adjust fade-out speed

    // ✅ Clamp opacity to a valid range (0.0 - 1.0)
    opacity = opacity.clamp(0.0, 1.0);

    // ✅ Ensure it moves up
    position.y -= 20 * dt;

    // ✅ Remove if fully transparent
    if (opacity <= 0.01) {
      removeFromParent();
      print("🔔 Notification removed");
    }
  }
}
