import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'player.dart';
import 'main.dart'; // ✅ Ensure this is imported

class FireAura extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame> {
  final Player player;

  FireAura({required this.player})
      : super(size: Vector2(100, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 🔥 Load the sprite sheet for fire aura animation
    final spriteSheet = await gameRef.loadSprite('fire_aura.png');

    // 🔥 Define frame size (assuming 3 horizontal frames)
    final spriteSize = Vector2(100, 100); // Adjust based on your sprite sheet
    final frameCount = 3; // Number of frames in your sprite sheet

    // 🔥 Create animation from frames
    animation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: 0.1, // Adjust speed for smooth looping
        textureSize: spriteSize,
      ),
    );

    // 🔥 Keep it centered on the player
    position = player.position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = player.position.clone(); // 🔥 Keep it following the player
  }
}
