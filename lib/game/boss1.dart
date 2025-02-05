import 'dart:math'; // ✅ Fix for cos and sin
import 'dart:ui'; // ✅ Fix for VoidCallback
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:whisper_warriors/game/staggerbar.dart';
import 'player.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'damagenumber.dart';
import 'explosion.dart';
import 'dropitem.dart';
import 'fireaura.dart';
import 'staggerable.dart';

class Boss1 extends BaseEnemy with Staggerable {
  bool enraged = false;
  double attackCooldown = 4.0;
  double timeSinceLastAttack = 0.0;
  final double damageNumberInterval = 0.5;
  bool hasDroppedItem = false;
  final Function(double) onHealthChanged;
  final ValueChanged<double>
      onStaggerChanged; // ✅ Notify HUD of stagger changes
  VoidCallback onDeath; // ✅ Handles boss death
  late final double maxHealth; // ✅ Store original max health
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation walkAnimation;
  late StaggerBar staggerBar;
  final Random random = Random();
  final ValueNotifier<double> bossStaggerNotifier; // ✅ UI Notifier

  Boss1({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onStaggerChanged,
    required this.bossStaggerNotifier,
  }) : super(
          player: player,
          health: health,
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    staggerBar = StaggerBar(maxStagger: staggerThreshold);
  }

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
    add(RectangleHitbox()); // ✅ Ensure hitbox exists
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateStagger(dt); // ✅ Handles stagger logic

    if (isStaggered) {
      // ✅ Ensure stagger recovers after time passes
      return;
    }
    timeSinceLastAttack += dt;
    timeSinceLastDamageNumber += dt;

    _updateMovement(dt);
    _handleAttacks(dt);
  }

  @override
  void _triggerStagger() {
    if (isStaggered) return;

    print("⚡ BOSS STAGGERED!");
    isStaggered = true;
    speed *= 0.2; // ✅ Slow down movement
    attackCooldown *= 1.5; // ✅ Slow attack speed

    add(OpacityEffect.to(
        0.5, EffectController(duration: 0.2))); // ✅ Visual effect

    Future.delayed(Duration(seconds: 3), () {
      isStaggered = false;
      speed /= 0.5;
      attackCooldown /= 1.5;
      staggerProgress = 0; // ✅ Reset stagger bar
      bossStaggerNotifier.value = 0; // ✅ Update UI
      add(OpacityEffect.to(1.0, EffectController(duration: 0.2)));
    });
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
      timeSinceLastAttack = 0.0;
    }
  }

  void _shootProjectiles() {
    print("🔥 Boss is firing projectiles!");

    int numProjectiles = 4;
    double spreadAngle = 360;

    for (int i = 0; i < numProjectiles; i++) {
      double angle =
          (-spreadAngle / 2) + (i * (spreadAngle / (numProjectiles - 1)));
      double radians = angle * (pi / 180);

      Vector2 projectileVelocity = Vector2(cos(radians), sin(radians)) * 800;

      Vector2 spawnOffset = projectileVelocity.normalized() * 50;
      Vector2 spawnPosition = position.clone() + spawnOffset;

      final bossProjectile = Projectile.bossProjectile(
        damage: 20,
        velocity: projectileVelocity,
      )
        ..position = spawnPosition
        ..size = Vector2(65, 65)
        ..anchor = Anchor.center;

      gameRef.add(bossProjectile);
      print("🔥 Boss Projectile fired at angle: $angle°");
    }
  }

  @override
  void takeDamage(int baseDamage, {bool isCritical = false}) {
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }

    int finalDamage =
        isCritical ? (baseDamage * player.critMultiplier).toInt() : baseDamage;

    // ✅ **Double damage if staggered**
    if (isStaggered) {
      finalDamage *= 2;
    }

    health -= finalDamage;
    onHealthChanged(health.toDouble());

    // ✅ **Slower stagger accumulation**
    staggerProgress += baseDamage * 0.04; // 🔥 Reduce accumulation rate
    staggerProgress = staggerProgress.clamp(0, 100);
    bossStaggerNotifier.value = staggerProgress;

    // ✅ **Check if stagger should trigger**
    if (staggerProgress >= 100) {
      triggerStagger();
    }

    if (timeSinceLastDamageNumber >= damageNumberInterval ||
        timeSinceLastDamageNumber == 0.0) {
      final damageNumber = DamageNumber(
        finalDamage,
        position.clone() + Vector2(0, -20),
        isCritical: isCritical,
      );
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0.0;
    }

    if (health <= (maxHealth * 0.3) && !enraged) {
      enraged = true;
      _enterEnrageMode();
    }

    if (health <= 0) {
      die();
    }
  }

  @override
  void triggerStagger() {
    if (isStaggered) return;

    print("⚡ BOSS STAGGERED!");
    isStaggered = true;
    speed *= 0.5;
    attackCooldown *= 1.5;

    // 🔥 **Apply Red Glow Effect**
    add(ColorEffect(
      const Color(0xFFFF0000), // Red Tint
      EffectController(duration: 3.0, reverseDuration: 0.5),
    ));

    add(OpacityEffect.to(0.5, EffectController(duration: 0.2)));

    Future.delayed(Duration(seconds: 3), () {
      isStaggered = false;
      speed /= 0.5;
      attackCooldown /= 1.5;
      staggerProgress = 0;
      bossStaggerNotifier.value = 0;

      add(OpacityEffect.to(1.0, EffectController(duration: 0.2)));
    });
  }

  void _enterEnrageMode() {
    speed *= 1.5;
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
      final drop = DropItem(expValue: 100, spriteName: 'gold_coin.png')
        ..position = position.clone();
      gameRef.add(drop);
    }

    onDeath();
    gameRef.add(Explosion(position));
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is FireAura) {
      print("🔥 Umbrathos hit by Whispering Flames!");
      takeDamage(other.damage.toInt());
    }
  }
}
