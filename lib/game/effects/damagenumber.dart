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
  final Color? customColor; // Add color parameter
  double timer = 1.0;
  late List<SpriteComponent> digitSprites = [];
  final Random _random = Random();

  static final Map<int, Sprite> numberSprites = {}; // ✅ Store loaded sprites
  static Sprite? minusSprite; // ✅ Cache minus sign sprite

  DamageNumber(
    this.damage,
    this.initialPosition, {
    this.isCritical = false,
    this.isPlayer = false,
    this.customColor, // Add to constructor
  }) {
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
    if (numberSprites.isEmpty) {
      for (int i = 0; i <= 9; i++) {
        numberSprites[i] = await gameRef.loadSprite('$i.png');
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

    if (isPlayer) {
      // ✅ Add a minus sign only for player damage
      if (minusSprite != null) {
        SpriteComponent minus = SpriteComponent(
          sprite: minusSprite,
          size: Vector2(10, 10), // ✅ Smaller minus sign
          position: Vector2(offsetX, 0),
          anchor: Anchor.center,
        );
        digitSprites.add(minus);
        add(minus);
        offsetX += 8; // ✅ Adjust spacing
      }
    }

    for (int i = 0; i < damageString.length; i++) {
      int digit = int.parse(damageString[i]);

      SpriteComponent digitSprite = SpriteComponent(
        sprite: numberSprites[digit],
        size: isPlayer
            ? Vector2(10, 10)
            : Vector2(16, 16), // ✅ Smaller for player
        position: Vector2(offsetX, 0),
        anchor: Anchor.center,
      );

      digitSprites.add(digitSprite);
      add(digitSprite);

      offsetX += isPlayer ? 8 : 14; // ✅ Smaller spacing for player damage
    }

    // Modified color logic
    if (customColor != null) {
      // Use custom color if provided
      for (var sprite in digitSprites) {
        sprite.add(
          ColorEffect(
            customColor!,
            EffectController(duration: 0.2),
          ),
        );
      }
    } else if (isPlayer) {
      // Default red for player damage if no custom color
      for (var sprite in digitSprites) {
        sprite.add(
          ColorEffect(
            const Color(0xFFFF4444),
            EffectController(duration: 0.2),
          ),
        );
      }
    }
  }
}
