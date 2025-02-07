import 'enemy.dart';
import 'package:flame/sprite.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart'; // ✅ Import for Vector2
import 'package:whisper_warriors/game/player/player.dart';

class Wave2Enemy extends BaseEnemy {
  Wave2Enemy({
    required Player player, // ✅ Use named parameters
    required double speed,
    required int health,
    required Vector2 size,
  }) : super(
          player: player,
          speed: speed,
          health: health,
          size: size,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('mob2.png'),
      srcSize: Vector2(128, 128),
    );

    animation = spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.2,
      to: 2,
    );

    add(RectangleHitbox());
  }
}
