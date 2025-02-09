import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';

class NotificationComponent extends TextComponent {
  final RogueShooterGame gameRef;
  final Vector2 positionOffset;
  double timer = 0.0;
  double opacity = 1.0;
  late TextPaint _textPaint;

  NotificationComponent(
      this.gameRef, String message, this.positionOffset, TextStyle textStyle)
      : super(text: message) {
    _textPaint = TextPaint(style: textStyle);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    textRenderer = _textPaint;

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

    opacity -= dt * 0.5;
    opacity = opacity.clamp(0.0, 1.0);
    position.y -= 20 * dt;

    if (opacity <= 0.01) {
      removeFromParent();
      print("🔔 Notification removed");
    }
  }
}

// ✅ Persistent Loot Log UI (formerly `lootnotificationbar.dart`)
class LootNotificationBar extends PositionComponent {
  final RogueShooterGame gameRef;
  final List<LootEntry> lootEntries = [];
  static const int maxEntries = 5; // Max number of items shown at once

  LootNotificationBar(this.gameRef) : super(size: Vector2(250, 120));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 1000; // ✅ Higher priority to keep it above other elements
    await Future.delayed(
        Duration(milliseconds: 100)); // Ensure proper game size

    // ✅ Set an initial fixed position (top-left)
    position = gameRef.size / 2 - size / 2;
    print("📌 LootNotificationBar Position Set: $position");
  }

  void addLootNotification(String itemName, String rarity, int quantity) {
    if (lootEntries.length >= maxEntries) {
      lootEntries.removeAt(0); // Remove oldest entry
    }

    Color textColor;
    switch (rarity) {
      case "Rare":
        textColor = Colors.blue;
        break;
      case "Epic":
        textColor = Colors.purple;
        break;
      case "Legendary":
        textColor = Colors.orange;
        break;
      default:
        textColor = Colors.white;
    }

    lootEntries.add(LootEntry(itemName, rarity, quantity, textColor));
    print(
        "📜 Loot Log Updated: ${lootEntries.map((e) => e.itemName).toList()}");

    // ✅ Remove only this entry after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      lootEntries.removeWhere(
          (entry) => entry.itemName == itemName && entry.rarity == rarity);
      print("🗑️ Removed $itemName from loot log");
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.player != null) {
      // ✅ Position loot box **below** the player
      position = gameRef.player.position.clone() + Vector2(-125, 70);
    }
  }

  @override
  void render(Canvas canvas) {
    if (lootEntries.isEmpty) return; // ✅ Don't render if no loot

    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Radius.circular(10),
      ),
      paint,
    );

    double offsetY = 10;
    for (final entry in lootEntries.reversed) {
      final textStyle = TextStyle(
        color: entry.textColor, // ✅ Apply color per item rarity
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

      final textPaint = TextPaint(style: textStyle);

      textPaint.render(
          canvas,
          "${entry.quantity}x ${entry.itemName} (${entry.rarity})",
          Vector2(10, offsetY));
      offsetY += 20;
    }
  }
}

class LootEntry {
  final String itemName;
  final String rarity;
  final int quantity;
  final Color textColor; // ✅ New field for text color

  LootEntry(this.itemName, this.rarity, this.quantity, this.textColor);
}
