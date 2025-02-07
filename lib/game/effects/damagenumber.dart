import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:whisper_warriors/game/main.dart';

class DamageNumber extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Vector2 initialPosition;
  final int damage;
  final bool isCritical; // ✅ Detect if it's a crit hit
  double timer = 1.0; // Display time in seconds
  late List<SpriteComponent> digitSprites = [];

  static final Map<int, Sprite> numberSprites = {}; // Store loaded sprites

  DamageNumber(this.damage, this.initialPosition, {this.isCritical = false}) {
    position = initialPosition;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;

    await _loadSpritesIfNeeded();
    _createDamageNumberSprites();

    // ✅ Floating Effect (moves upward)
    add(MoveEffect.by(Vector2(0, -30), EffectController(duration: 0.5)));

    if (isCritical) {
      // ✅ Magnify & Shrink Effect for Crits
      add(ScaleEffect.to(Vector2.all(2.5), EffectController(duration: 0.1))
        ..onComplete = () => add(
            ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.1))));
    }

    // ✅ Auto-remove after timer ends
    add(RemoveEffect(delay: 1.0));
  }

  /// Loads sprites into a map if they haven't been loaded yet
  Future<void> _loadSpritesIfNeeded() async {
    if (numberSprites.isEmpty) {
      for (int i = 0; i <= 9; i++) {
        numberSprites[i] = await gameRef.loadSprite('$i.png');
      }
    }
  }

  /// Creates and positions sprite digits
  void _createDamageNumberSprites() {
    String damageString = damage.toString();
    double offsetX = 0;

    for (int i = 0; i < damageString.length; i++) {
      int digit = int.parse(damageString[i]);

      SpriteComponent digitSprite = SpriteComponent(
        sprite: numberSprites[digit],
        size: isCritical
            ? Vector2(24, 24)
            : Vector2(16, 16), // ✅ Bigger for crits
        position: Vector2(offsetX, 0),
        anchor: Anchor.center,
      );

      digitSprites.add(digitSprite);
      add(digitSprite);

      offsetX += isCritical ? 18 : 14; // ✅ Slightly larger spacing for crits
    }
  }
}
