import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'staggerable.dart';

class Boss1 extends BaseEnemy with Staggerable {
  bool enraged = false;
  bool isFading = false; // ✅ Boss enters fading phase at 50% health
  double attackCooldown = 4.0;
  double timeSinceLastAttack = 0.0;
  final double damageNumberInterval = 0.5;
  bool hasDroppedItem = false;
  final Function(double) onHealthChanged;
  final ValueChanged<double> onStaggerChanged;
  VoidCallback onDeath;
  late final double maxHealth;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation walkAnimation;
  late StaggerBar staggerBar;
  final Random random = Random();
  final ValueNotifier<double> bossStaggerNotifier;
  int attackCount = 0;
  bool alternatePattern = false;

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
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateStagger(dt);

    if (isStaggered) return;

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
      timeSinceLastAttack = 0.0;
    }
  }

  void _shootProjectiles() {
    print("🔥 Boss is firing projectiles!");

    List<double> cardinalAngles = [0, 90, 180, 270];
    List<double> diagonalAngles = [45, 135, 225, 315];

    List<double> angles = alternatePattern ? diagonalAngles : cardinalAngles;
    alternatePattern = !alternatePattern;

    if (attackCount % 4 == 3) {
      angles = angles.reversed.toList();
      print("🔄 Reversing projectile direction!");
    }

    attackCount++;

    // ✅ **If the boss is fading, randomly remove 2 projectiles**
    if (isFading) {
      angles.shuffle();
      angles = angles.sublist(0, 2);
      print("👁 **Some projectiles have vanished!**");
    }

    for (double angle in angles) {
      double radians = angle * (pi / 180);

      Vector2 projectileVelocity = Vector2(cos(radians), sin(radians)) * 800;
      Vector2 spawnOffset = projectileVelocity.normalized() * 50;
      Vector2 spawnPosition = position.clone() + spawnOffset;

      final bossProjectile = Projectile.bossProjectile(
        damage: 20,
        velocity: projectileVelocity,
      )
        ..position = spawnPosition
        ..size = Vector2(40, 40)
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

    if (isStaggered) {
      finalDamage *= 2;
    }

    health -= finalDamage;
    onHealthChanged(health.toDouble());

    if (health <= maxHealth * 0.5 && !isFading) {
      _enterFadingPhase();
    }

    staggerProgress += baseDamage * 0.04;
    staggerProgress = staggerProgress.clamp(0, 100);
    bossStaggerNotifier.value = staggerProgress;

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

      if (isFading) {
        damageNumber.priority = 1000; // ✅ Ensures it's drawn above everything
      }
    }

    if (health <= (maxHealth * 0.3) && !enraged) {
      enraged = true;
      _enterEnrageMode();
    }

    if (health <= 0) {
      die();
    }
  }

  void _enterFadingPhase() {
    print("👁 **The Fading King is fading!** - Boss is now invisible!");
    isFading = true;
    add(OpacityEffect.to(0.0, EffectController(duration: 2.0)));
  }

  @override
  void triggerStagger() {
    if (isStaggered) return;

    print("⚡ BOSS STAGGERED!");
    isStaggered = true;
    speed *= 0.5;
    attackCooldown *= 1.5;

    add(ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 3.0, reverseDuration: 0.5),
    ));

    add(OpacityEffect.to(1.0, EffectController(duration: 0.5)));

    Future.delayed(Duration(seconds: 3), () {
      isStaggered = false;
      speed /= 0.5;
      attackCooldown /= 1.5;
      staggerProgress = 0;
      bossStaggerNotifier.value = 0;

      if (isFading) {
        add(OpacityEffect.to(0.0, EffectController(duration: 1.0)));
        print("👁 **The Fading King vanishes once more!**");
      }
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
}
