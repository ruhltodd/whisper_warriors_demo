import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
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
import 'package:whisper_warriors/game/main.dart'; //Import it here!
import 'package:whisper_warriors/game/abilities/abilities.dart';

class Boss1 extends BaseEnemy with Staggerable {
  final ValueNotifier<double> healthNotifier;
  bool enraged = false;
  bool isFading = false;
  // Removed _startTeleportation (it's redundant)
  bool hasTriggeredX195 = false;
  bool hasTriggeredX190 = false;
  bool hasTriggeredX165 = false;
  bool hasTriggeredX150 = false;
  double attackCooldown = 4.0;
  double timeSinceLastAttack = 0.0;
  double _timeSinceLastTeleportShoot = 0;
  final double damageNumberInterval = 0.5; // Unused in mock, but kept
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
  bool _tripleDamaged = false;
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

  //Double Vars
  double originalSpeed = 0;
  double originalAttackCooldown = 0;

  double _teleportShootRemainingTime = 0; // Keep this

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
          health: health,
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0); // Mocked
    healthBar = BossHealthBar(
      // Mocked
      bossHealth: healthNotifier, // Pass healthNotifier
      maxBossHealth: health.toDouble(),
      segmentSize: segmentSize, // Pass segmentSize
    );
    _playerStandingTimer = Timer(
      standingThreshold,
      onTick: () {
        if (!_isExecutingTargetedAttack) {
          targetPlayer();
        }
      },
    );
  }

  @override
  Future<void> onLoad() async {
    // Mock animations (replace with your actual loading)
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

    originalSpeed = speed;
    originalAttackCooldown = attackCooldown;

    animation = idleAnimation;
    add(RectangleHitbox());
    //gameRef.add(staggerBar); // Removed for Mocking
    setLanded(true);
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress; //Mocked
    bossStaggerNotifier.value = staggerProgress;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Add debug logs to understand the state
    if (gameRef.player.isDead) {
      print('🚫 Player is dead - Boss update skipped');
      return; // Exit early if player is dead
    }

    // Only proceed if not already in fading phase and exactly at X165
    if (!isFading && position.x == 165) {
      print('📍 Boss at exact position X165, triggering fade phase');
      _enterFadingPhase();
    }

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
      // Moved this BEFORE the remaining time check
      if (_teleportShootRemainingTime > 0) {
        _teleportOutsidePlayerRange();
        _shootRandomProjectiles(dt); // Called every frame while time remains
      } else {
        isFading = false;
        _teleportShootRemainingTime = 0; // Ensure it's reset
        _returnToNormalState();
      }
      _teleportShootRemainingTime -= dt; // Decrement *after* using the value
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
      _enterFadingPhase(); // Use _enterFadingPhase directly
    }

    if (currentSegment <= 150 && !hasTriggeredX150) {
      hasTriggeredX150 = true;
      triggerX150Mechanics();
    }

    if (!_isExecutingTargetedAttack) {
      timeSinceLastAttack += dt;
      //timeSinceLastDamageNumber += dt; // Remove since there are no damage numbers in the mock
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
    if (!isFading) {
      // Only attack if NOT fading
      timeSinceLastAttack += dt;
      if (timeSinceLastAttack >= attackCooldown) {
        _shootProjectiles();
        timeSinceLastAttack = 0.0;
      }
    }
  }

  void _shootProjectiles() {
    //No changes required
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
        damage: 15,
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
      {bool isCritical = false,
      bool isEchoed = false,
      bool isFlameDamage = false}) {
    //No changes required
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }

    int finalDamage = isCritical
        ? (baseDamage * player.critMultiplier).toInt()
        : baseDamage.toInt();

    double newDamage = finalDamage.toDouble();
    if (_tripleDamaged == true) {
      newDamage = finalDamage * 3;
    }
    // Apply damage to the local class
    double currentHealth = healthNotifier.value;
    currentHealth -= newDamage;
    // Update
    healthNotifier.value = currentHealth.toDouble();

    onHealthChanged(healthNotifier.value);
    print('⚠️ Boss took damage! Health: ${healthNotifier.value}');

    // Check for phase transitions
    if (healthNotifier.value <= 165000 && !hasTriggeredX165) {
      print('✅ TRIGGERING 165 MECHANICS!');
      hasTriggeredX165 = true;
      _enterFadingPhase(); // Use _enterFadingPhase directly
    }

    applyStaggerDamage(finalDamage, isCritical: isCritical);

    // Check for death and call onDeath
    if (healthNotifier.value <= 0) {
      die();
      onDeath();
    }
  }

  @override
  void applyStaggerVisuals() {
    add(ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 5.0, reverseDuration: 5.0),
    ));
  }

  void targetPlayer() {
    //No changes required
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
      _enterFadingPhase();
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
    //No changes required
    _isTargetingPlayer = false;
    _isExecutingTargetedAttack = false;
    _playerStandingTimer?.reset();
    _warningCircle?.removeFromParent();
    _warningCircle = null;
    _projectileTimer?.stop();
    _projectileTimer = null;
  }

  void pauseNormalAttackPattern() {
    //No changes required
    timeSinceLastAttack = 0;
    attackCooldown = 999999;
  }

  void resumeNormalAttackPattern() {
    //No changes required
    attackCooldown = enraged ? 2.8 : 4.0;
    timeSinceLastAttack = 0;
  }

  void _teleportOutsidePlayerRange() {
    //No changes required
    final Vector2 playerPos = player.position;
    Vector2 newPosition;
    int attempts = 0;

    do {
      double angle = random.nextDouble() * 2 * pi;
      double distance = 100 + (random.nextDouble() * 500);
      Vector2 offset = Vector2(cos(angle) * distance, sin(angle) * distance);
      newPosition = playerPos + offset;
      attempts++;
      if (attempts > 100) break;
    } while (newPosition.x < 0 ||
        newPosition.x > gameRef.size.x ||
        newPosition.y < 0 ||
        newPosition.y > gameRef.size.y);

    if (attempts > 100) {
      newPosition = Vector2(1280 / 2, 720 / 2);
    }

    position = newPosition;
    print('🚀 Boss teleported to $position');
  }

  void _shootRandomProjectiles(double dt) {
    //No changes required
    if (_teleportShootRemainingTime <= 0) return; // Don't shoot if time is up

    _timeSinceLastTeleportShoot += dt;
    if (_timeSinceLastTeleportShoot >= 1.0) {
      _timeSinceLastTeleportShoot = 0;
      for (int i = 0; i < 6; i++) {
        double angle = random.nextDouble() * (pi * 2);
        Vector2 velocity = Vector2(cos(angle), sin(angle)) * 500;

        final bossProjectile = Projectile.bossProjectile(
          damage: 15, // Example damage
          velocity: velocity,
        )
          ..position = position.clone()
          ..size = Vector2(40, 40)
          ..anchor = Anchor.center;

        gameRef.add(bossProjectile);
      }
      print('💥 Boss fired projectiles');
    }
  }

  void _returnToNormalState() {
    //No changes required
    print('⚡ Boss returning to normal!');
    isFading = false;
    attackCooldown = originalAttackCooldown;
    speed = originalSpeed;

    add(OpacityEffect.to(1.0, EffectController(duration: 1.5)));
    add(RectangleHitbox());
  }

  @override
  void onRemove() {
    _playerStandingTimer?.stop();
    _projectileTimer?.stop();
    _warningCircle?.removeFromParent();
    super.onRemove();
  }

  // COMBINE triggerX165Mechanics and _enterFadingPhase
  void _enterFadingPhase() {
    if (isFading) return;

    print('🔥 Boss at X165 - Triggering Fading Phase!');
    isFading = true;
    _teleportShootRemainingTime = 15;

    // Make boss untargetable immediately
    isTargetable = false;
    gameRef.player.disableShooting();
    print('🎯 Boss marked as untargetable');

    // Start fade effect
    add(OpacityEffect.to(
      0.0,
      EffectController(duration: 1.5),
      onComplete: () {
        print('🌟 Boss fade complete - waiting before teleport phase');
        // Move off-screen immediately after fade
        position = Vector2(-9999, -9999);

        // Add delay before starting teleport phase
        Future.delayed(Duration(seconds: 2), () {
          if (isMounted) {
            _startTeleportAndShootPhase();
          }
        });
      },
    ));

    pauseNormalAttackPattern();
    removeWhere((component) => component is RectangleHitbox);

    // Adjust the timing to account for fade (1.5s) + delay (2s)
    Future.delayed(Duration(seconds: 15), () {
      if (isMounted) {
        isTargetable = true;
        gameRef.player.enableShooting();
        print('✅ Boss targetable again after fading phase');
      }
    });
  }

  void _startTeleportAndShootPhase() {
    print('👻 Boss starting teleport and shoot phase after delay');
    // Your existing teleport and shoot logic here
  }

  void triggerX195Mechanics() {
    //No changes required
    print('🔥 Boss at X195 - Triggering new mechanics!');
    // Increase attack speed
    attackCooldown *= 0.8;
    // Add more mechanics as needed
  }

  void triggerX190Mechanics() {
    //No changes required
    print('💥 Boss at X190 - Triggering rage mechanics!');
    // Increase projectile count
    alternatePattern = true;
    // Add more mechanics as needed
  }

  void triggerX150Mechanics() {
    //No changes required
    print('⚡ Boss at X150 - Final phase mechanics!');
    attackCooldown *= 0.7;
    speed *= 1.5;
  }
}
