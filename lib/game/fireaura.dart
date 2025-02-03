import 'package:flame/components.dart';
import 'package:flame/collisions.dart'; // ✅ Import for collision
import 'player.dart';
import 'main.dart';
import 'enemy.dart';

class FireAura extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  // ✅ Add CollisionCallbacks
  final Player player;
  double baseDamagePerSecond = 3.0; // 🔥 Base damage

  FireAura({required this.player})
      : super(size: Vector2(100, 100), anchor: Anchor.center);

  double get damage =>
      baseDamagePerSecond * player.spiritMultiplier; // ✅ Scaled damage

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = await gameRef.loadSprite('fire_aura.png');
    final spriteSize = Vector2(100, 100);
    final frameCount = 3;

    animation = SpriteAnimation.fromFrameData(
      spriteSheet.image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: 0.1,
        textureSize: spriteSize,
      ),
    );

    position = player.position.clone();

    // ✅ Add a circular hitbox slightly larger than the sprite
    add(
      CircleHitbox.relative(1.2, parentSize: size)
        ..collisionType = CollisionType.passive,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = player.position.clone(); // 🔥 Keep it following the player
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is BaseEnemy) {
      // ✅ Ensure damage is applied to all enemies, including bosses
      print("🔥 FireAura hit ${other.runtimeType}!");
      other.takeDamage(damage.toInt()); // ✅ Apply damage
    }
  }
}
