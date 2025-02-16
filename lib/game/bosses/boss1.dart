import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'package:whisper_warriors/game/bosses/bosshealthbar.dart';
import 'staggerable.dart';
import 'package:flame/timer.dart';
import 'package:whisper_warriors/game/main.dart';

class Boss1 extends BaseEnemy with Staggerable {
  final ValueNotifier<double> healthNotifier;
  bool enraged = false;
  bool isFading = false;
  bool hasTriggeredX195 = false;
  bool hasTriggeredX190 = false;
  bool hasTriggeredX165 = false;
  bool hasTriggeredX150 = false;
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
  Timer? _playerStandingTimer;
  Timer? _projectileTimer;
  Vector2? _lastPlayerPosition;
  static const double standingThreshold = 1.0;
  bool _isTargetingPlayer = false;
  CircleComponent? _warningCircle;
  static const double projectileCooldown = 0.5;
  bool _isExecutingTargetedAttack = false;
  late BossHealthBar healthBar;
  final double segmentSize; // Store segmentSize

  Boss1({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onStaggerChanged,
    required this.bossStaggerNotifier,
    this.segmentSize = 1000, // Default segmentSize
  })  : healthNotifier = ValueNotifier(health.toDouble()),
        super(
          player: player,
          health: health, // Remove
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0);
    _playerStandingTimer = Timer(
      standingThreshold,
      onTick: () {
        if (!_isExecutingTargetedAttack) {
          targetPlayer();
        }
      },
    );

    // Initialize the healthBar
    healthBar = BossHealthBar(
      bossHealth: healthNotifier, // Pass healthNotifier
      maxBossHealth: health.toDouble(),
      segmentSize: segmentSize, // Pass segmentSize
    );
  }

  @override
  Future<void> onLoad() async {
    walkAnimation = await gameRef.loadSpriteAnimation(
      'boss1_walk.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.3,
      ),
    );

    idleAnimation = await gameRef.loadSpriteAnimation(
      'boss1_idle.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: Vector2(128, 128),
        stepTime: 0.6,
      ),
    );

    animation = idleAnimation;
    add(RectangleHitbox());
    gameRef.add(staggerBar);
    setLanded(true);
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress;
    bossStaggerNotifier.value = staggerProgress;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final currentHealth = healthNotifier.value;
    final currentSegment = (currentHealth / segmentSize).ceil();

    print('🧐 Boss Health Segment: $currentSegment');
    print(
        '🤖 Boss Update - HasLanded: $_hasLanded, IsTargeting: $_isTargetingPlayer');

    updateStagger(dt);
    updateStaggerBar();

    if (isStaggered) {
      print('😵 Boss is Staggered');
      return;
    }

    _updateMovement(dt);
    if (isFading) {
      removeWhere((component) => component is RectangleHitbox);
    }

    // Check segment thresholds and trigger mechanics
    if (currentSegment <= 195 && !hasTriggeredX195) {
      hasTriggeredX195 = true;
      triggerX195Mechanics();
    }

    if (currentSegment <= 190 && !hasTriggeredX190) {
      hasTriggeredX190 = true;
      triggerX190Mechanics();
    }

    if (currentSegment <= 165 && !hasTriggeredX165) {
      print('✅ TRIGGERING 165 MECHANICS!');
      hasTriggeredX165 = true;
      triggerX165Mechanics();
    }

    if (currentSegment <= 150 && !hasTriggeredX150) {
      hasTriggeredX150 = true;
      triggerX150Mechanics();
    }

    if (!_isExecutingTargetedAttack) {
      timeSinceLastAttack += dt;
      timeSinceLastDamageNumber += dt;
      _handleAttacks(dt);

      final currentPlayerPos = player.position;
      if (_lastPlayerPosition != null &&
          (_lastPlayerPosition! - currentPlayerPos).length < 1) {
        _playerStandingTimer?.update(dt);
      } else {
        _playerStandingTimer?.stop();
        _playerStandingTimer = Timer(
          standingThreshold,
          onTick: () {
            if (!_isExecutingTargetedAttack) {
              targetPlayer();
            }
          },
        );
      }
      _lastPlayerPosition = currentPlayerPos.clone();
    }

    if (_isTargetingPlayer && _projectileTimer != null) {
      _projectileTimer!.update(dt);
    }
  }

  void setLanded(bool value) {
    _hasLanded = value;
  }

  void _updateMovement(double dt) {
    if (!_hasLanded) return;

    final Vector2 direction = (player.position - position).normalized();
    final double distanceToPlayer = (player.position - position).length;

    if (distanceToPlayer > 20) {
      animation = walkAnimation;
      if (!_isExecutingTargetedAttack) {
        position += direction * speed * dt;
      }
    } else {
      animation = idleAnimation;
    }

    if (distanceToPlayer < 10) {
      print('💥 Boss collided with Player - dealing damage!');
      player.takeDamage(10);
      player.position += -direction * 40;
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
  void takeDamage(double baseDamage,
      {bool isCritical = false, bool isEchoed = false}) {
    //super.takeDamage(baseDamage, isCritical: isCritical, isEchoed: isEchoed);
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }
    int finalDamage = isCritical
        ? (baseDamage * player.critMultiplier).toInt()
        : baseDamage.toInt();

    // Apply damage to the local class
    double currentHealth = healthNotifier.value;
    currentHealth -= finalDamage;
    // Update
    healthNotifier.value = currentHealth.toDouble();

    onHealthChanged(healthNotifier.value);
    print('⚠️ Boss took damage! Health: ${healthNotifier.value}');

    // Check for phase transitions
    if (healthNotifier.value <= 165000 && !hasTriggeredX165) {
      print('✅ TRIGGERING 165 MECHANICS!');
      hasTriggeredX165 = true;
      triggerX165Mechanics();
    }

    applyStaggerDamage(finalDamage, isCritical: isCritical);
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

  @override
  void applyStaggerVisuals() {
    add(ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 5.0, reverseDuration: 5.0),
    ));
  }

  void targetPlayer() {
    if (_isExecutingTargetedAttack) return;

    _isExecutingTargetedAttack = true;
    _isTargetingPlayer = true;
    pauseNormalAttackPattern();

    // Base projectile speed that increases based on boss phase
    double projectileSpeed = 200.0;

    // Increase speed based on current segment
    final currentHealth = healthNotifier.value;
    final currentSegment = (currentHealth / segmentSize).ceil();

    if (currentSegment <= 195) {
      projectileSpeed = 300.0;
    }
    if (currentSegment <= 190) {
      projectileSpeed = 310.0;
    }
    if (currentSegment <= 165) {
      triggerX165Mechanics();
    }
    if (currentSegment <= 150) {
      projectileSpeed = 500.0;
    }

    _projectileTimer = Timer(
      projectileCooldown,
      onTick: () {
        if (_isTargetingPlayer) {
          final Vector2 direction = (player.position - position).normalized();
          if (direction.length > 0) {
            final bossProjectile = Projectile.bossProjectile(
              damage: 15,
              velocity:
                  direction * projectileSpeed, // Use the phase-based speed
            )
              ..position = position.clone()
              ..size = Vector2.all(40)
              ..anchor = Anchor.center;

            gameRef.add(bossProjectile);
          }
        }
      },
      repeat: true,
    )..start();

    Future.delayed(const Duration(seconds: 3), () {
      _stopTargeting();
      _isExecutingTargetedAttack = false;
      resumeNormalAttackPattern();

      Future.delayed(const Duration(seconds: 5), () {
        if (isMounted) {
          _isExecutingTargetedAttack = false;
          _isTargetingPlayer = false;
          _playerStandingTimer?.reset();
          _lastPlayerPosition = null;
        }
      });
    });
  }

  void _stopTargeting() {
    _isTargetingPlayer = false;
    _isExecutingTargetedAttack = false;
    _playerStandingTimer?.reset();
    _warningCircle?.removeFromParent();
    _warningCircle = null;
    _projectileTimer?.stop();
    _projectileTimer = null;
  }

  void pauseNormalAttackPattern() {
    timeSinceLastAttack = 0;
    attackCooldown = 999999;
  }

  void resumeNormalAttackPattern() {
    attackCooldown = enraged ? 2.8 : 4.0;
    timeSinceLastAttack = 0;
  }

  void triggerX195Mechanics() {
    print('🔥 Boss at X195 - Triggering new mechanics!');
    // Increase attack speed
    attackCooldown *= 0.8;
    // Add more mechanics as needed
  }

  void triggerX190Mechanics() {
    print('💥 Boss at X190 - Triggering rage mechanics!');
    // Increase projectile count
    alternatePattern = true;
    // Add more mechanics as needed
  }

  void triggerX165Mechanics() {
    print('⚡ Boss at X165 - Entering Final Phase Mechanics!');

    if (isFading) return;
    isFading = true;
    print('🕶 Boss is now fading...');
    double originalSpeed = speed;
    double originalAttackCooldown = attackCooldown;

    add(OpacityEffect.to(0.0, EffectController(duration: 1.5), onComplete: () {
      print('🕵️‍♂️ Opacity effect finished, starting teleport phase.');
      removeWhere((component) => component is RectangleHitbox);
      attackCooldown = 9999;

      _teleportAndShootLoop(15, originalSpeed, originalAttackCooldown);
    }));
  }

  void _teleportAndShootLoop(int durationInSeconds, double originalSpeed,
      double originalAttackCooldown) {
    int remainingTime = durationInSeconds;
    print('🚀 Teleport sequence started! Duration: $durationInSeconds seconds');
    Timer shootingTimer = Timer(3, repeat: true, onTick: () {
      if (remainingTime <= 0) {
        _returnToNormalState(originalSpeed, originalAttackCooldown);
        return;
      }

      _teleportOutsidePlayerRange();
      _shootRandomProjectiles();
      remainingTime -= 3;
      print('🚀 Projectile shot! Remaining: $remainingTime seconds');
    });

    shootingTimer.start();
  }

  void _teleportOutsidePlayerRange() {
    final Vector2 playerPos = player.position;
    Vector2 newPosition;

    do {
      newPosition = Vector2(
        playerPos.x + (random.nextDouble() * 800 - 400),
        playerPos.y + (random.nextDouble() * 800 - 400),
      );
    } while (
        (newPosition - playerPos).x < 256 && (newPosition - playerPos).y < 256);

    position = newPosition;
    print('🚀 Boss teleported to $position');
  }

  void _shootRandomProjectiles() {
    int numProjectiles = 6 + random.nextInt(4);
    for (int i = 0; i < numProjectiles; i++) {
      double angle = random.nextDouble() * (pi * 2);
      Vector2 velocity = Vector2(cos(angle), sin(angle)) * 600;

      final bossProjectile = Projectile.bossProjectile(
        damage: 15,
        velocity: velocity,
      )
        ..position = position.clone()
        ..size = Vector2(40, 40)
        ..anchor = Anchor.center;

      gameRef.add(bossProjectile);
    }
    print('💥 Boss fired projectiles');
  }

  void _returnToNormalState(
      double originalSpeed, double originalAttackCooldown) {
    print('⚡ Boss returning to normal!');

    isFading = false;
    attackCooldown = originalAttackCooldown;
    speed = originalSpeed;

    add(OpacityEffect.to(1.0, EffectController(duration: 1.5), onComplete: () {
      add(RectangleHitbox());
    }));
  }

  void triggerX150Mechanics() {
    print('⚡ Boss at X150 - Final phase mechanics!');
    attackCooldown *= 0.7;
    speed *= 1.5;
  }

  @override
  void onRemove() {
    _playerStandingTimer?.stop();
    _projectileTimer?.stop();
    _warningCircle?.removeFromParent();
    super.onRemove();
  }
}
