import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';

class ShadowBlades extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Player player;
  final int baseDamage = 12;
  final double bladeSpeed = 750;
  final double bladeCooldown = 0.5; // ✅ Faster attack speed
  double _elapsedTime = 0.0;

  ShadowBlades({required this.player});

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;

    if (_elapsedTime >= bladeCooldown) {
      _shootBlade();
      _elapsedTime = 0.0;
    }
  }

  void _shootBlade() {
    // ✅ Find closest enemy or boss
    BaseEnemy? target = _findClosestTarget();

    if (target == null) {
      return;
    }

    Vector2 direction = (target.position - player.position).normalized();
    double rotationAngle = direction.angleTo(Vector2(1, 0));

    _spawnBlade(direction, rotationAngle);

    // ✅ **Roll Cursed Echo ONCE per blade thrown**
    if (player.hasAbility<CursedEcho>() && gameRef.random.nextDouble() < 0.20) {
      print("🔄 Cursed Echo triggered for Shadow Blade!");
      Future.delayed(Duration(milliseconds: 100), () {
        _spawnBlade(direction, rotationAngle);
      });
    }
  }

  void _spawnBlade(Vector2 direction, double rotationAngle) {
    final blade = ShadowBladeProjectile(
      damage: (baseDamage * player.spiritMultiplier).toInt(),
      velocity: direction * bladeSpeed,
      player: player,
      rotationAngle: rotationAngle, // ✅ Ensures correct rotation
    )
      ..position = player.position.clone()
      ..size = Vector2(48, 16) // Blade sprite size
      ..anchor = Anchor.center;

    gameRef.add(blade);
  }

  BaseEnemy? _findClosestTarget() {
    final enemies = gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) return null;

    BaseEnemy? closest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
      double distance = (enemy.position - player.position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = enemy;
      }
    }
    return closest;
  }
}

class ShadowBladeProjectile extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final int damage;
  final Vector2 velocity;
  final Player player;
  final double rotationAngle;
  double maxDistance = 1200;
  Vector2 startPosition = Vector2.zero();

  ShadowBladeProjectile({
    required this.damage,
    required this.velocity,
    required this.player,
    required this.rotationAngle,
  }) {
    angle = rotationAngle; // ✅ Rotate in direction of movement
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    animation = SpriteAnimation.fromFrameData(
      await gameRef.images.load('shadowblades.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2(48, 16),
        loop: true,
      ),
    );
    startPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if ((position - startPosition).length >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BaseEnemy) {
      bool isCritical = gameRef.random.nextDouble() < (player.critChance / 100);
      int finalDamage =
          isCritical ? (damage * player.critMultiplier).toInt() : damage;

      other.takeDamage(finalDamage, isCritical: isCritical);

      // ✅ **No longer rolling Cursed Echo per enemy hit**
      // ✅ **Now triggers per blade when first thrown**
    }

    // ❌ Ignore **player's own** projectiles (except other Shadow Blades)
    else if (other is Projectile && other is! ShadowBladeProjectile) {
      return;
    }

    super.onCollision(intersectionPoints, other);
  }
}
