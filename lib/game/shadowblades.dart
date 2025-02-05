import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:async';
import 'dart:math';
import 'player.dart';
import 'enemy.dart';
import 'main.dart';

class ShadowBlades extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Player player;
  final int baseDamage = 10;
  final double bladeSpeed = 700;
  final int maxBlades;
  final double bladeCooldown = 1.5;
  double _elapsedTime = 0.0;
  bool _canShoot = true;

  ShadowBlades({required this.player}) : maxBlades = player.spiritLevel;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;

    if (_elapsedTime >= bladeCooldown && _canShoot) {
      _shootBlades();
      _elapsedTime = 0.0;
      _canShoot = false;
      Future.delayed(Duration(milliseconds: 500), () => _canShoot = true);
    }
  }

  void _shootBlades() {
    print("⚔️ Throwing Shadow Blades!");
    for (int i = 0; i < maxBlades; i++) {
      double angleOffset =
          (i - (maxBlades - 1) / 2) * (pi / 8); // Spread effect
      Vector2 velocity =
          Vector2(cos(angleOffset), sin(angleOffset)) * bladeSpeed;
      _spawnBlade(velocity);
    }
  }

  void _spawnBlade(Vector2 velocity) {
    if (!isMounted) return; // ✅ Prevent errors before mounting

    final blade = ShadowBladeProjectile(
      damage: baseDamage * player.spiritMultiplier.toInt(),
      velocity: velocity,
      player: player,
    )
      ..position = player.position.clone()
      ..size = Vector2(48, 16) // Blade sprite size
      ..anchor = Anchor.center;

    gameRef.add(blade); // ✅ Ensures gameRef is available
  }
}

class ShadowBladeProjectile extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  // ✅ Fix gameRef issue

  final int damage;
  final Vector2 velocity;
  final Player player;

  ShadowBladeProjectile(
      {required this.damage, required this.velocity, required this.player}) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    animation = SpriteAnimation.fromFrameData(
      await gameRef.images.load('shadow_blades.png'), // ✅ Use await
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2(48, 16),
        loop: true,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.x < -100 ||
        position.x > gameRef.size.x + 100 ||
        position.y < -100 ||
        position.y > gameRef.size.y + 100) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BaseEnemy) {
      other.takeDamage(damage, isCritical: false);
    }
    super.onCollision(intersectionPoints, other);
  }
}
