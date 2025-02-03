import 'dart:math'; // ✅ Fix for cos and sin
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'player.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'damagenumber.dart';
import 'explosion.dart';
import 'dropitem.dart';
import 'main.dart';

class Boss1 extends BaseEnemy {
  bool enraged = false; // ✅ Enrage mode flag
  double attackCooldown = 3.0;
  double timeSinceLastAttack = 0.0;
  final double damageNumberInterval = 0.5;
  bool hasDroppedItem = false;

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation walkAnimation;
  final Random random = Random(); // ✅ Fix: Use local random instance

  Boss1({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
  }) : super(
          player: player,
          health: health,
          speed: speed, // ✅ Speed is mutable now
          size: size,
        );

  @override
  Future<void> onLoad() async {
    idleAnimation = await gameRef.loadSpriteAnimation(
      'boss1_idle.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: Vector2(128, 128),
        stepTime: 0.6,
      ),
    );

    walkAnimation = await gameRef.loadSpriteAnimation(
      'boss1_walk.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.3,
      ),
    );

    animation = idleAnimation;
    add(RectangleHitbox()); // ✅ Ensure the hitbox exists
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastAttack += dt;
    timeSinceLastDamageNumber += dt;

    _updateMovement(dt);
    _handleAttacks(dt);
  }

  void _updateMovement(double dt) {
    final Vector2 direction = (player.position - position).normalized();

    if ((player.position - position).length > 20) {
      animation = walkAnimation;
      position += direction * speed * dt;
    } else {
      animation = idleAnimation;
    }

    if ((player.position - position).length < 10) {
      player.takeDamage(10);
      _knockback(-direction * 40);
    }
  }

  void _handleAttacks(double dt) {
    timeSinceLastAttack += dt;

    if (timeSinceLastAttack >= attackCooldown) {
      _shootProjectiles();
      timeSinceLastAttack = 0.0; // ✅ Reset attack timer
    }
  }

  void _shootProjectiles() {
    print("🔥 Boss is firing projectiles!");

    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * (pi / 180);

      Vector2 projectileVelocity =
          Vector2(cos(angle), sin(angle)) * 800; // ✅ Increase Speed

      final bossProjectile = Projectile.bossProjectile(
        damage: 20,
        velocity: projectileVelocity, // ✅ Ensure velocity is applied
      )
        ..position = position.clone()
        ..size = Vector2(80, 80) // ✅ Bigger size for visibility
        ..anchor = Anchor.center;

      gameRef.add(bossProjectile);
      print("🔥 Boss Projectile fired at ${position}");
    }
  }

  @override
  void takeDamage(int baseDamage, {bool isCritical = false}) {
    int finalDamage =
        isCritical ? (baseDamage * player.critMultiplier).toInt() : baseDamage;

    health -= finalDamage;

    if (timeSinceLastDamageNumber >= damageNumberInterval) {
      final damageNumber = DamageNumber(
        finalDamage,
        position.clone() + Vector2(0, -20),
        isCritical: isCritical,
      );
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0.0;
    }

    if (health <= (health * 0.3) && !enraged) {
      enraged = true;
      _enterEnrageMode();
    }

    if (health <= 0) {
      die();
    }
  }

  void _enterEnrageMode() {
    speed *= 1.5; // ✅ Mutability fixed
    attackCooldown *= 0.7;

    add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.5))
      ..onComplete = () {
        add(OpacityEffect.to(
          0.7,
          EffectController(duration: 0.5),
        ));
      });
  }

  void _knockback(Vector2 force) {
    add(MoveEffect.by(force, EffectController(duration: 0.2)));
  }

  @override
  void die() {
    if (!hasDroppedItem) {
      hasDroppedItem = true;
      final drop = DropItem(expValue: 100)..position = position.clone();
      gameRef.add(drop);
    }

    gameRef.add(Explosion(position));
    removeFromParent();
  }
}
