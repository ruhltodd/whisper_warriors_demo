import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'staggerable.dart';

class LaserBeam extends PositionComponent with HasGameRef<RogueShooterGame> {
  final Vector2 startPosition;
  final Vector2 direction;
  final double length;
  final double width;
  final double damagePerSecond;

  LaserBeam({
    required this.startPosition,
    required this.direction,
    required this.length,
    required this.width,
    required this.damagePerSecond,
  }) {
    position = startPosition;
    size = Vector2(length, width);
    angle = direction.angleTo(Vector2(1, 0)); // ✅ Rotate laser toward player
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.redAccent, Colors.orange, Colors.yellow],
      ).createShader(Rect.fromLTWH(0, 0, length, width))
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(length, 0), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ Check if the player is inside the beam
    if (_playerInBeam()) {
      gameRef.player
          .takeDamage((damagePerSecond * dt).toInt()); // ✅ Now gameRef works!
    }
  }

  bool _playerInBeam() {
    final player = gameRef.player;
    final playerDistance = (player.position - startPosition).length;
    return playerDistance <= length &&
        (player.position - startPosition).normalized().dot(direction) > 0.9;
  }
}

class Boss2 extends BaseEnemy with Staggerable {
  bool enraged = false;
  double attackCooldown = 4.0;
  double timeSinceLastAttack = 0.0;
  final double damageNumberInterval = 0.5;
  bool hasDroppedItem = false;
  final Function(double) onHealthChanged;
  final ValueChanged<double> onStaggerChanged;
  VoidCallback onDeath;
  late final double maxHealth;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation attackAnimation;
  late StaggerBar staggerBar;
  final Random random = Random();
  final ValueNotifier<double> bossStaggerNotifier;
  int attackCount = 0;
  bool alternatePattern = false;

  Boss2({
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
      'boss2.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: Vector2(128, 128),
        stepTime: 0.6,
      ),
    );

    attackAnimation = await gameRef.loadSpriteAnimation(
      'boss2.png',
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

// boss2 doesn't move, so we can remove the walkAnimation and _updateMovement method
  void _updateMovement(double dt) {
    animation = (player.position - position).length < 10
        ? attackAnimation
        : idleAnimation;

    if ((player.position - position).length < 10) {
      player.takeDamage(10);
    }
  }

  void _handleAttacks(double dt) {
    timeSinceLastAttack += dt;

    if (timeSinceLastAttack >= attackCooldown) {
      _activateLaserBeam();
      timeSinceLastAttack = 0.0;
    }
  }

  void _activateLaserBeam() {
    Vector2 direction = (player.position - position).normalized();

    // ✅ Laser properties
    double beamLength = 300; // Adjust beam range
    double beamWidth = 10;
    double damagePerSecond = 20;

    // ✅ Create a laser beam effect
    gameRef.add(LaserBeam(
      startPosition: position.clone(),
      direction: direction,
      length: beamLength,
      width: beamWidth,
      damagePerSecond: damagePerSecond,
    ));

    List<double> angles = [0, 45, 90, 135, 180, 225, 270, 315];
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
      final dropItems = _getDropItems();
      final lootBox =
          LootBox(items: dropItems.map((dropItem) => dropItem.item).toList());
      lootBox.position = position.clone();
      gameRef.add(lootBox);
      print("🗃️ LootBox spawned at position: ${lootBox.position}");
    }

    onDeath();
    gameRef.add(Explosion(position));
    removeFromParent();
  }

  List<DropItem> _getDropItems() {
    final List<DropItem> dropItems = [];

    // Add the gold coin
    dropItems.add(DropItem(item: GoldCoin()));

    // Add the random loot item
    final item = LootTable.getRandomLoot();
    if (item != null) {
      dropItems.add(DropItem(item: item));
    }

    return dropItems;
  }
}
