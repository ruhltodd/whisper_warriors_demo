import 'dart:ui';
import 'dart:math' show Random;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:whisper_warriors/game/main.dart';

class DamageNumber extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Vector2 initialPosition;
  final int damage;
  final bool isCritical;
  final bool isPlayer; // ✅ Flag to differentiate player damage
  final bool isWhisperingFlames; // Add this property
  final Vector2? customSize; // Add this property
  double timer = 1.0;
  late List<SpriteComponent> digitSprites = [];
  final Random _random = Random();

  static final Map<int, Sprite> numberSprites = {}; // ✅ Store loaded sprites
  static Sprite? minusSprite; // ✅ Cache minus sign sprite
  static final Map<int, Sprite> orangeNumberSprites =
      {}; // Add cache for orange sprites

  DamageNumber(this.damage, this.initialPosition,
      {this.isCritical = false,
      this.isPlayer = false,
      this.isWhisperingFlames = false,
      this.customSize}) {
    position = initialPosition + _getRandomOffset();
  }

  Vector2 _getRandomOffset() {
    return Vector2(
      _random.nextDouble() * 20 - 10,
      _random.nextDouble() * 20 - 10,
    );
  }

  double _getRandomHorizontalMove() {
    return _random.nextDouble() * 40 - 20;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;

    await _loadSpritesIfNeeded();
    _createDamageNumberSprites();

    add(MoveEffect.by(
      Vector2(_getRandomHorizontalMove(), -30),
      EffectController(duration: 0.5),
    ));

    if (isCritical && !isPlayer) {
      // ✅ Magnify & Shrink Effect for Crits (Only for enemies)
      add(ScaleEffect.to(Vector2.all(2.5), EffectController(duration: 0.1))
        ..onComplete = () => add(
            ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.1))));
    }

    // ✅ Auto-remove after timer ends
    add(RemoveEffect(delay: 1.0));
  }

  /// Loads number sprites & minus sign if not already loaded
  Future<void> _loadSpritesIfNeeded() async {
    // Load regular number sprites
    if (numberSprites.isEmpty) {
      for (int i = 0; i <= 9; i++) {
        numberSprites[i] = await gameRef.loadSprite('$i.png');
      }
    }

    // Load orange number sprites
    if (orangeNumberSprites.isEmpty) {
      for (int i = 0; i <= 9; i++) {
        orangeNumberSprites[i] = await gameRef.loadSprite('$i-or.png');
      }
    }

    if (minusSprite == null) {
      minusSprite = await gameRef.loadSprite('minus.png'); // ✅ Load "-" sprite
    }
  }

  /// Creates and positions sprite digits
  void _createDamageNumberSprites() {
    String damageString =
        damage.abs().toString(); // ✅ Convert to absolute value
    double offsetX = 0;

    // Default sizes if no custom size is provided
    final Vector2 playerSize = customSize ?? Vector2(10, 10);
    final Vector2 enemySize = customSize ?? Vector2(16, 16);
    final double playerSpacing = customSize != null ? customSize!.x * 0.8 : 8;
    final double enemySpacing = customSize != null ? customSize!.x * 0.875 : 14;

    if (isPlayer) {
      // ✅ Add a minus sign only for player damage
      if (minusSprite != null) {
        SpriteComponent minus = SpriteComponent(
          sprite: minusSprite,
          size: playerSize,
          position: Vector2(offsetX, 0),
          anchor: Anchor.center,
        );
        digitSprites.add(minus);
        add(minus);
        offsetX += playerSpacing; // ✅ Adjust spacing
      }
    }

    for (int i = 0; i < damageString.length; i++) {
      int digit = int.parse(damageString[i]);

      // Use orange sprites for WhisperingFlames damage
      Sprite digitSprite = isWhisperingFlames
          ? orangeNumberSprites[digit]!
          : numberSprites[digit]!;

      SpriteComponent digitComponent = SpriteComponent(
        sprite: digitSprite,
        size: isPlayer ? playerSize : enemySize,
        position: Vector2(offsetX, 0),
        anchor: Anchor.center,
      );

      digitSprites.add(digitComponent);
      add(digitComponent);

      offsetX += isPlayer
          ? playerSpacing
          : enemySpacing; // ✅ Smaller spacing for player damage
    }

    // Only apply red tint for player damage if it's not WhisperingFlames
    if (isPlayer && !isWhisperingFlames) {
      for (var sprite in digitSprites) {
        sprite.add(
          ColorEffect(
            const Color(0xFFFF4444), // 🔴 Red for player damage
            EffectController(duration: 0.2),
          ),
        );
      }
    }
  }
}
