import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Explosion extends SpriteAnimationComponent with HasGameRef {
  Explosion(Vector2 position)
      : super(
          size: Vector2(64, 64), // Adjust as needed
          anchor: Anchor.center,
          position: position,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // ✅ Load the explosion sprite sheet
    final spriteSheet = SpriteSheet(
      image:
          await gameRef.images.load('explosion.png'), // Make sure this exists
      srcSize: Vector2(64, 64), // Adjust this based on each frame's size
    );

    // ✅ Create animation from 50 frames
    animation = spriteSheet.createAnimation(
      row: 0, // Adjust if necessary
      stepTime: 0.02, // Speed of explosion animation (adjust as needed)
      to: 9, // Use all 50 frames
      loop: false, // ✅ Only plays once
    );

    // ✅ Auto-remove after animation ends
    animationTicker?.onComplete = () {
      removeFromParent();
    };
  }
}
