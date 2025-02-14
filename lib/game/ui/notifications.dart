import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';

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
  final List<NotificationItem> notifications = [];
  static const double notificationDuration = 3.0; // Duration in seconds

  // Reduce box size
  LootNotificationBar(this.gameRef)
      : super(size: Vector2(250, 100)); // Reduced from 350x120

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
      lootEntries.removeAt(0);
    }

    // Extract just the rarity name from ItemRarity.epic format
    final rarityName = rarity.contains(".")
        ? rarity.split(".").last.toUpperCase()
        : rarity.toUpperCase();

    // Updated color mapping
    Color textColor;
    switch (rarityName) {
      case "COMMON":
        textColor = Colors.grey;
        break;
      case "UNCOMMON":
        textColor = Colors.green;
        break;
      case "RARE":
        textColor = Colors.blue;
        break;
      case "EPIC":
        textColor = Colors.purple;
        break;
      case "LEGENDARY":
        textColor = Colors.orange;
        break;
      default:
        textColor = Colors.white;
    }

    // Format the display text without the ItemRarity. prefix
    final cleanItemName = itemName.contains("ItemRarity.")
        ? itemName.replaceAll(RegExp(r'\s*\(ItemRarity\.[^)]+\)'), '')
        : itemName;

    lootEntries.add(LootEntry(cleanItemName, rarityName, quantity, textColor));

    Future.delayed(Duration(seconds: 3), () {
      lootEntries.removeWhere((entry) =>
          entry.itemName == cleanItemName && entry.rarity == rarityName);
    });
  }

  void showNotification(String message, ItemRarity rarity) {
    // Create color based on rarity
    Color textColor;
    switch (rarity) {
      case ItemRarity.common:
        textColor = Colors.white;
        break;
      case ItemRarity.uncommon:
        textColor = Colors.green;
        break;
      case ItemRarity.rare:
        textColor = Colors.blue;
        break;
      case ItemRarity.epic:
        textColor = Colors.purple;
        break;
      case ItemRarity.legendary:
        textColor = Colors.orange;
        break;
      default:
        textColor = Colors.white;
    }

    // Add new notification
    notifications.add(NotificationItem(
      message: message,
      color: textColor,
      timeRemaining: notificationDuration,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.player != null) {
      // ✅ Position loot box **below** the player
      position = gameRef.player.position.clone() + Vector2(-125, 70);
    }

    // Update notification timers and remove expired ones
    notifications.removeWhere((notification) {
      notification.timeRemaining -= dt;
      return notification.timeRemaining <= 0;
    });
  }

  @override
  void render(Canvas canvas) {
    if (lootEntries.isEmpty) return;

    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final padding = 30.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            -padding / 2, -padding / 2, size.x + padding, size.y + padding),
        Radius.circular(10),
      ),
      paint,
    );

    double offsetY = 15;
    for (final entry in lootEntries.reversed) {
      final textStyle = TextStyle(
        color: entry.textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

      // Format text without the enum notation
      final text = "${entry.quantity}x ${entry.itemName}";
      final maxWidth = size.x - 40;

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: maxWidth);

      final displayText = textPainter.width > maxWidth
          ? _ellipsizeText(text, maxWidth, textStyle)
          : text;

      final textPaint = TextPaint(
        style: textStyle,
      );

      textPaint.render(
        canvas,
        displayText,
        Vector2(20, offsetY),
      );
      offsetY += 25;
    }

    double yOffset = 50; // Starting Y position from top

    for (var notification in notifications) {
      final textSpan = TextSpan(
        text: notification.message,
        style: TextStyle(
          color: notification.color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(gameRef.size.x - textPainter.width - 20, yOffset),
      );

      yOffset += 30; // Space between notifications
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

class NotificationItem {
  final String message;
  final Color color;
  double timeRemaining;

  NotificationItem({
    required this.message,
    required this.color,
    required this.timeRemaining,
  });
}

// Helper function for text truncation
String _ellipsizeText(String text, double maxWidth, TextStyle style) {
  var truncated = text;
  while (truncated.length > 0) {
    final textSpan = TextSpan(
      text: "$truncated...",
      style: style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);

    if (textPainter.width <= maxWidth) {
      return "$truncated...";
    }
    truncated = truncated.substring(0, truncated.length - 1);
  }
  return "...";
}
