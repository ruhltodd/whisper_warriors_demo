import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';
import 'package:whisper_warriors/game/items/items.dart';

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
  static const int maxEntries = 5;
  final List<NotificationItem> notifications = [];
  static const double notificationDuration = 3.0;

  late Sprite itemSprite;
  late final ParticleSystemComponent particles;
  bool isAnimating = false;
  Timer? revealTimer;
  SpriteComponent? itemIcon;
  SpriteComponent? _pendingRemovalIcon;
  RectangleComponent? _pendingRemovalPanel;
  RectangleComponent? _pendingRemovalBorder;
  TextComponent? _pendingRemovalReceivedText;
  TextComponent? _pendingRemovalItemText;
  bool _needsCleanup = false;
  bool _cleanupScheduled = false;
  List<PositionComponent> _activeComponents = [];

  // Add a queue for pending notifications
  final List<_PendingNotification> _notificationQueue = [];
  bool _processingNotification = false;

  LootNotificationBar(this.gameRef) : super(size: Vector2(250, 100));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 1000; // Keep it above other elements

    // Initialize particle system
    particles = ParticleSystemComponent(
      particle: Particle.generate(
        count: 50,
        lifespan: 2,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 30),
          speed: Vector2(
            Random().nextDouble() * 100 - 50,
            Random().nextDouble() * -50 - 50,
          ),
          position: size / 2,
          child: CircleParticle(
            radius: 2,
            paint: Paint()..color = const Color(0xFFA020F0),
          ),
        ),
      ),
    );

    position = gameRef.size / 2 - size / 2;
  }

  void addLootNotification(String itemName, String rarity, int quantity) async {
    // Skip all coin notifications
    if (itemName.toLowerCase().contains("coin")) {
      return;
    }

    // Rest of the notification code for special items
    final rarityName = rarity.contains(".")
        ? rarity.split(".").last.toUpperCase()
        : rarity.toUpperCase();

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
        textColor = const Color(0xFFA335EE);
        break;
      case "LEGENDARY":
        textColor = const Color(0xFFFF8000);
        break;
      default:
        textColor = Colors.white;
    }

    final cleanItemName = itemName.contains("ItemRarity.")
        ? itemName.replaceAll(RegExp(r'\s*\(ItemRarity\.[^)]+\)'), '')
        : itemName;

    // Add to queue only for non-coin items
    _notificationQueue.add(_PendingNotification(
      spriteName: Item.createByName(cleanItemName)?.spriteName ?? '',
      itemName: cleanItemName,
      color: textColor,
    ));
  }

  Future<void> showItemAnimation(
      String spriteName, String itemName, Color color) async {
    if (isAnimating) return;
    isAnimating = true;

    try {
      // Load sprite first
      itemSprite = await gameRef.loadSprite(spriteName);
      await Future.delayed(Duration.zero);

      if (!isMounted) {
        isAnimating = false;
        return;
      }

      final startPos = size / 2 + Vector2(0, -20);
      final endPos = size / 2;
      final isHighValue = color == const Color(0xFFA335EE) || // Epic
          color == const Color(0xFFFF8000); // Legendary

      // Create all components first
      final components = <PositionComponent>[];

      // Black background panel
      final panel = FadingComponent(
        size: Vector2(300, 40),
        position: startPos,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.black
          ..maskFilter =
              isHighValue ? const MaskFilter.blur(BlurStyle.outer, 2) : null
          ..style = PaintingStyle.fill,
      );
      components.add(panel);

      // Icon
      itemIcon = SpriteComponent(
        sprite: itemSprite,
        position: startPos + Vector2(-120, 0),
        size: Vector2(32, 32),
        anchor: Anchor.center,
      );
      components.add(itemIcon!);

      // "You received" text in gold
      final receivedText = TextComponent(
        text: 'You received',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFFFD100), // WoW gold color
            fontSize: 16,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        position: startPos + Vector2(-80, -8),
        anchor: Anchor.centerLeft,
      );
      components.add(receivedText);

      // Item name with appropriate rarity color
      final itemNameText = TextComponent(
        text: itemName,
        textRenderer: TextPaint(
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: isHighValue ? color.withOpacity(0.5) : Colors.black,
                offset: const Offset(1, 1),
                blurRadius: isHighValue ? 4 : 2,
              ),
            ],
          ),
        ),
        position: startPos + Vector2(-80, 8),
        anchor: Anchor.centerLeft,
      );
      components.add(itemNameText);

      // Add all components first
      for (final component in components) {
        add(component);
      }

      // Store active components
      _activeComponents = components;

      // Add a small delay before starting the animation
      await Future.delayed(const Duration(milliseconds: 100));

      // Add fade and move effects
      for (final component in components) {
        if (component is OpacityProvider) {
          component.add(
            OpacityEffect.fadeIn(
              EffectController(duration: 0.3),
            ),
          );
        }

        component.add(
          MoveEffect.to(
            endPos + (component.position - startPos),
            EffectController(duration: 0.3, curve: Curves.easeOutBack),
          ),
        );
      }

      // Schedule cleanup
      Future.delayed(const Duration(seconds: 2), () {
        if (isMounted) {
          for (final component in _activeComponents) {
            if (component.isMounted) {
              component.removeFromParent();
            }
          }
          _activeComponents.clear();
          isAnimating = false;
        }
      });
    } catch (e) {
      print('❌ Error in showItemAnimation: $e');
      isAnimating = false;
    }
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

    // Only update the timer
    if (revealTimer != null) {
      revealTimer!.update(dt);
    }

    // Process next notification if we're ready
    if (!isAnimating && _notificationQueue.isNotEmpty) {
      final nextNotification = _notificationQueue.removeAt(0);
      showItemAnimation(
        nextNotification.spriteName,
        nextNotification.itemName,
        nextNotification.color,
      );
    }

    if (gameRef.player != null) {
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

// Helper class for queued notifications
class _PendingNotification {
  final String spriteName;
  final String itemName;
  final Color color;

  _PendingNotification({
    required this.spriteName,
    required this.itemName,
    required this.color,
  });
}

class FadingComponent extends PositionComponent implements OpacityProvider {
  final Paint _paint;
  double _opacity = 0;

  FadingComponent({
    required Vector2 position,
    required Vector2 size,
    required Paint paint,
    Anchor anchor = Anchor.center,
  }) : _paint = paint {
    this.position = position;
    this.size = size;
    this.anchor = anchor;
  }

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value.clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        size.toRect(), _paint..color = _paint.color.withOpacity(_opacity));
  }
}
