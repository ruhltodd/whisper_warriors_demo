import 'package:flame/components.dart';
import 'package:flame/collisions.dart'; // ✅ Import for collision
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';

class FireAura extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final Player player;
  double baseDamagePerSecond = 3.0; // 🔥 Base damage
  double elapsedTime = 0.0;
  double range = 150.0; // 🔥 Aura range

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
    elapsedTime += dt;
    position = player.position.clone(); // 🔥 Keep it following the player

    // ✅ Damage enemies every 1 second
    if (elapsedTime >= 1.0) {
      elapsedTime = 0.0;

      // ✅ **Roll Cursed Echo chance ONCE per tick (not per enemy)**
      bool cursedEchoTriggered = player.hasAbility<CursedEcho>() &&
          (gameRef.random.nextDouble() < 0.20);

      for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
        if ((enemy.position - position).length < range) {
          bool isCritical =
              gameRef.random.nextDouble() < (player.critChance / 100);
          int finalDamage = isCritical
              ? (damage * player.critMultiplier).toInt()
              : damage.toInt();

          enemy.takeDamage(finalDamage, isCritical: isCritical);

          // ✅ **If Cursed Echo triggered, reapply Fire Aura damage once**
          if (cursedEchoTriggered) {
            print("🔥 Cursed Echo triggered Fire Aura repeat!");
            Future.delayed(Duration(milliseconds: 100), () {
              enemy.takeDamage(finalDamage, isCritical: isCritical);
            });
          }
        }
      }
    }
  }
}
