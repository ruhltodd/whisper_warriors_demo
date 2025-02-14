import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'staggerable.dart';

class Boss1 extends BaseEnemy with Staggerable {
  bool enraged = false;
  bool isFading = false;
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
  bool _hasLanded = false;

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
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0);
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
    gameRef.add(staggerBar);
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress;
    bossStaggerNotifier.value = staggerProgress;
  }

// Stagger updates!
  @override
  void update(double dt) {
    super.update(dt);
    updateStagger(dt);
    updateStaggerBar();

    if (isStaggered) return;

    timeSinceLastAttack += dt;
    timeSinceLastDamageNumber += dt;

    _updateMovement(dt);
    _handleAttacks(dt);
  }

// end of stagger updates
  void setLanded(bool value) {
    _hasLanded = value;
  }

  void _updateMovement(double dt) {
    if (!_hasLanded) return;

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
    List<double> cardinalAngles = [0, 90, 180, 270];
    List<double> diagonalAngles = [45, 135, 225, 315];

    List<double> angles = alternatePattern ? diagonalAngles : cardinalAngles;
    alternatePattern = !alternatePattern;

    if (attackCount % 4 == 3) {
      angles = angles.reversed.toList();
    }

    attackCount++;

    if (isFading) {
      angles.shuffle();
      angles = angles.sublist(0, 2);
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
    }
  }

  @override
  void takeDamage(double baseDamage, {bool isCritical = false}) {
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }
    int finalDamage = isCritical
        ? (baseDamage * player.critMultiplier).toInt()
        : baseDamage.toInt();
    health -= finalDamage;
    onHealthChanged(health.toDouble());
    applyStaggerDamage(finalDamage, isCritical: isCritical); //stagger update

    if (health <= maxHealth * 0.5 && !isFading) {
      _enterFadingPhase();
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
    isFading = true;
    add(OpacityEffect.to(0.0, EffectController(duration: 2.0)));
  }

  void _enterEnrageMode() {
    speed *= 0.5;
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

    if (gameRef.spawnController != null) {
      gameRef.spawnController!.onBoss1Death();
    } else {
      print("⚠️ SpawnController is missing! Boss2 won't spawn.");
    }
  }

  List<DropItem> _getDropItems() {
    final List<DropItem> dropItems = [];

    dropItems.add(DropItem(item: GoldCoin()));

    final item = LootTable.getRandomLoot();
    if (item != null) {
      dropItems.add(DropItem(item: item));
    }

    return dropItems;
  }

  //stagger update
  @override
  void applyStaggerVisuals() {
    add(ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 5.0, reverseDuration: 5.0),
    ));
  }
}
