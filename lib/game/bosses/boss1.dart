import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/bosses/bosshealthbar.dart';
import 'staggerable.dart';
import 'package:flame/timer.dart';
import 'dart:async'; // Add this import at the top
import 'package:flame/input.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/ai/spawncontroller.dart';
import 'package:whisper_warriors/game/ai/wave2enemy.dart'; // Add this import

enum OrbitalPattern { NORMAL, EXPAND_CONTRACT, FIGURE_EIGHT, SPIRAL }

class Boss1 extends BaseEnemy with Staggerable, KeyboardHandler {
  final ValueNotifier<double> healthNotifier;
  bool enraged = false;
  bool isFading = false;
  // Removed _startTeleportation (it's redundant)
  bool hasTriggeredX195 = false;
  bool hasTriggeredX190 = false;
  bool hasTriggeredX165 = false;
  bool hasTriggeredX150 = false;
  bool hasTriggeredX120 = false;
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

  // Add these properties
  List<Projectile> _orbitalProjectiles = [];
  double _orbitalRadius = 600.0; // Increased radius for trapping
  double _orbitalSpeed = 3.0;
  double _orbitalAngle = 0.0;
  bool _isPerformingOrbitalAttack = false;
  double _storedSpeed = 0.0; // Add this to store original speed

  Timer? _coneTimer; // Add timer as class property

  bool _isUpdatingHealth = false; // Add flag to prevent recursive updates

  OrbitalPattern _currentPattern = OrbitalPattern.NORMAL;
  double _baseRadius = 400.0;
  double _patternTimer = 0;

  // Add these properties
  List<int> _availableProjectileIndices = [];
  Timer? _pullbackTimer;
  double _pullbackSpeed = 800.0;
  final Set<Projectile> _pullingProjectiles =
      {}; // Track which projectiles are being pulled

  // Add property
  bool hasTriggeredX80 = false;

  bool _lastTKeyState = false; // Track previous T key state

  // Add timer property
  bool _hasSpawnedDemo = false; // Flag to ensure we only spawn once

  // Add property
  bool _hasTriggeredX5 = false;

  Boss1({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onStaggerChanged,
    required this.bossStaggerNotifier,
    this.segmentSize = 1000,
  })  : healthNotifier = ValueNotifier(health.toDouble()),
        super(
          player: player,
          health: health,
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    print(
        '🏗️ Boss1 Constructor - Initial Health: $health, Max Health: $maxHealth');
    anchor = Anchor.center; // Set anchor in constructor
    print('🎯 Boss constructor - Setting initial position');
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
    print('🎯 Boss onLoad - Before position set');
    anchor = Anchor.center;
    _hasLanded = false;
    position = Vector2(1280 / 2, -300); // Start above screen

    print('💫 Boss initialization starting');

    // Add entrance animation
    Future.delayed(Duration(milliseconds: 500), () {
      if (!isMounted) return;

      print('🎬 Starting entrance animation');
      add(
        MoveToEffect(
          Vector2(1280 / 2, 1280 / 2),
          EffectController(
            duration: 1.0,
            curve: Curves.easeIn,
          ),
          onComplete: () {
            print('💥 Entrance animation complete');
            _hasLanded = true;
            if (gameRef != null) {
              gameRef.shakeScreen(gameRef.customCamera);
              // Add explosion effect
              gameRef.add(Explosion(position));
            }
            print('🛬 Has Landed set to: $_hasLanded');
          },
        ),
      );
    });

    await super.onLoad();

    // Load animations
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

    // Now trigger initial health update
    if (!_isUpdatingHealth) {
      _isUpdatingHealth = true;
      onHealthChanged(maxHealth);
      _isUpdatingHealth = false;
    }

    originalSpeed = speed;
    originalAttackCooldown = attackCooldown;

    return super.onLoad();
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress; //Mocked
    bossStaggerNotifier.value = staggerProgress;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isUpdatingHealth) return;

    // Check for death at X1 first
    if (healthBar.currentSegment <= 1) {
      print('💀 Boss health at X1 - Triggering death sequence');
      onBossDefeated();
      _spawnLootBox();
      removeAll(children.whereType<ColorEffect>());

      Future.delayed(const Duration(seconds: 4), () {
        if (gameRef.isMounted) {
          gameRef.victory();
        }
      });

      removeFromParent();
      return;
    }

    // Check for X5 orbital release
    if (healthBar.currentSegment <= 5 && !_hasTriggeredX5) {
      print('🌟 X5 threshold reached - Preparing orbital release!');
      _hasTriggeredX5 = true;

      // Ensure boss is in a state to release orbitals
      isStaggered = false;
      isFading = false;
      isTargetable = true;

      // Remove any effects that might interfere
      removeAll(children.whereType<ColorEffect>());

      // Release the orbitals
      print('🚀 Releasing orbital projectiles!');
      releaseOrbitalProjectiles();
      return;
    }

    // Check T key state using RawKeyboard
    final tKeyPressed =
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.keyT);

    // Toggle test mode only on key press (not hold)
    if (tKeyPressed && !_lastTKeyState) {
      gameRef.player.toggleTestMode();
    }
    _lastTKeyState = tKeyPressed;

    // Update orbital projectiles if active and above X140
    if (_isPerformingOrbitalAttack) {
      if (healthBar.currentSegment <= 140) {
        print('💫 Boss reaching X140 - Ending orbital phase');
        _endOrbitalAttack();
      } else {
        updateOrbitalProjectiles(dt);
      }
    }

    // Skip updates if staggered
    if (isStaggered) {
      print('😵 Boss is Staggered - Skipping update');
      return;
    }

    // Skip movement and animations during fading phase
    if (isFading) {
      if (_teleportShootRemainingTime > 0) {
        _timeSinceLastTeleportShoot += dt;
        if (_timeSinceLastTeleportShoot >= 1.0) {
          _teleportOutsidePlayerRange();
          _shootRandomProjectiles(dt);
          _timeSinceLastTeleportShoot = 0;
        }
      }
      _teleportShootRemainingTime -= dt;
      return;
    }

    // Regular update logic
    final currentHealth = healthNotifier.value;
    final currentSegment = (currentHealth / segmentSize).ceil();

    // Add X80 speed increase check
    if (!hasTriggeredX80 && currentSegment <= 80) {
      print('⚡ Boss reaching X80 - Increasing attack speed');
      hasTriggeredX80 = true;
      triggerX80Mechanics();
    }

    // Debug health and segment info
    print('🔢 Health: $currentHealth, Segment: $currentSegment');
    print(
        '🎯 Mechanics Status - X195: $hasTriggeredX195, X190: $hasTriggeredX190, X165: $hasTriggeredX165, X150: $hasTriggeredX150');

    // Ensure mechanics trigger in sequence
    if (!hasTriggeredX195 && currentSegment <= 195) {
      print('✨ Triggering X195');
      hasTriggeredX195 = true;
      triggerX195Mechanics();
    }

    if (hasTriggeredX195 && !hasTriggeredX190 && currentSegment <= 190) {
      print('✨ Triggering X190');
      hasTriggeredX190 = true;
      triggerX190Mechanics();
    }

    if (hasTriggeredX190 &&
        !hasTriggeredX165 &&
        !isFading &&
        currentSegment <= 165) {
      print('✨ Attempting X165');
      _enterFadingPhase();
    }

    if (hasTriggeredX165 &&
        !hasTriggeredX150 &&
        !isFading &&
        currentSegment <= 150) {
      print('✨ Triggering X150');
      hasTriggeredX150 = true;
      triggerX150Mechanics();
    }

    // Add X120 check here
    if (hasTriggeredX150 && !hasTriggeredX120 && currentSegment <= 120) {
      print('✨ Triggering X120');
      hasTriggeredX120 = true;
      triggerX120Mechanics();
    }

    updateStagger(dt);
    updateStaggerBar();

    if (!isFading) {
      _updateMovement(dt);
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

    // Add this to your existing update method
    updateOrbitalProjectiles(dt);

    if (_isPerformingOrbitalAttack) {
      // Force position and prevent movement during orbital attack
      position = Vector2(1280 / 2, (1280 / 2) - 100);
      speed = 0;

      // Update orbital projectiles
      if (_orbitalProjectiles.isNotEmpty) {
        _orbitalAngle += _orbitalSpeed * dt;

        for (int i = 0; i < _orbitalProjectiles.length; i++) {
          var projectile = _orbitalProjectiles[i];
          if (!projectile.isMounted) {
            _orbitalProjectiles.removeAt(i);
            i--;
            continue;
          }

          double angle =
              _orbitalAngle + (i * 2 * pi) / _orbitalProjectiles.length;
          Vector2 newPosition = Vector2(
            position.x + cos(angle) * _orbitalRadius,
            position.y + sin(angle) * _orbitalRadius,
          );

          projectile.position = newPosition;
        }
      }
    }

    // Debug print for current segment
    print(
        '🔍 Current Segment: ${healthBar.currentSegment}, X120 Triggered: $hasTriggeredX120');

    // Allow X120 to trigger while X150 is active
    if (currentSegment <= 120 && !hasTriggeredX120) {
      print('✅ Health below 120');
      hasTriggeredX120 = true;
      triggerX120Mechanics();
    }

    // Add attack pattern update
    if (alternatePattern && !isStaggered && !isFading) {
      timeSinceLastAttack += dt;

      if (timeSinceLastAttack >= attackCooldown) {
        _startAlternateAttackPattern(); // Choose random pattern each time
        timeSinceLastAttack = 0;
        attackCount++;
      }
    }
  }

  void setLanded(bool value) {
    _hasLanded = value;
    print('🛬 Boss landed state changed to: $_hasLanded');
  }

  void _updateMovement(double dt) {
    if (!isMounted) return;

    // Debug current state
    print('🔄 Movement Update - Landed: $_hasLanded, Fading: $isFading');

    final Vector2 direction = (player.position - position).normalized();
    final double distanceToPlayer = (player.position - position).length;

    if (distanceToPlayer > 20) {
      if (animation != walkAnimation) {
        print('🚶 Switching to walk animation');
      }
      animation = walkAnimation;

      if (!_isExecutingTargetedAttack) {
        position += direction * speed * dt;
      }
    } else {
      if (animation != idleAnimation) {
        print('🧍 Switching to idle animation');
      }
      animation = idleAnimation;
    }

    if (distanceToPlayer < 10) {
      player.takeDamage(10);
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
        damage: 3, //changed from 15 to 1 but change back to 15 for final
        velocity: projectileVelocity,
      )
        ..position = spawnPosition
        ..size = Vector2(50, 50)
        ..anchor = Anchor.center;

      gameRef.add(bossProjectile);
    }
  }

  void onBossDefeated() {
    print("💀 Boss defeated! Removing HUD elements...");

    // Remove boss health and stagger bars from the UI
    gameRef.overlays.remove('bossHealthBar');
    gameRef.overlays.remove('bossStaggerBar');

    // Remove any reference to boss-related UI elements
    gameRef.activeBossNameNotifier.value = null;
    gameRef.bossHealthNotifier.value = 0.0;
    gameRef.bossStaggerNotifier.value = 0.0;

    // Clean up orbital projectiles
    print('🗑️ Cleaning up ${_orbitalProjectiles.length} orbital projectiles');
    for (var projectile in [..._orbitalProjectiles]) {
      if (projectile != null && projectile.isMounted) {
        projectile.removeFromParent();
      }
    }
    _orbitalProjectiles.clear();
    _isPerformingOrbitalAttack = false;

    // Remove other projectiles
    gameRef.children.whereType<Projectile>().forEach((projectile) {
      if (projectile.isMounted) {
        print('🗑️ Removing projectile');
        projectile.removeFromParent();
      }
    });
  }

  void _endOrbitalAttack() {
    print('🌟 Releasing orbital projectiles');
    releaseOrbitalProjectiles();
  }

  @override
  void takeDamage(double baseDamage,
      {bool isCritical = false,
      bool isEchoed = false,
      bool isFlameDamage = false}) {
    if (!isMounted || healthNotifier.value <= 0 || _isUpdatingHealth) {
      print('⚠️ Damage blocked - Boss not mounted, dead, or updating');
      return;
    }

    _isUpdatingHealth = true;

    try {
      double actualDamage = getStaggeredDamage(baseDamage.toInt());
      double currentHealth = healthNotifier.value;
      double newHealth = (currentHealth - actualDamage).clamp(0.0, maxHealth);

      print(
          '💉 Taking damage: $actualDamage, Current Health: $currentHealth -> New Health: $newHealth');

      // Show damage number
      final damageNumber = DamageNumber(
        actualDamage.toInt(),
        position.clone() + Vector2(0, -20),
        isCritical: isCritical,
      );
      gameRef.add(damageNumber);

      // Update health notifiers in a single batch
      healthNotifier.value = newHealth;

      // Only call onHealthChanged if the value actually changed
      if (currentHealth != newHealth) {
        onHealthChanged(newHealth);
      }

      if (newHealth > 0) {
        applyStaggerDamage(actualDamage.toInt(), isCritical: isCritical);
      }

      if (newHealth <= 0) {
        die();
        onBossDefeated(); // ✅ Call cleanup function
        onDeath();
      }
    } finally {
      _isUpdatingHealth = false;
    }
  }

  // Add this method to handle health updates from external sources
  void updateHealth(double newHealth) {
    if (_isUpdatingHealth) return;

    _isUpdatingHealth = true;
    try {
      double clampedHealth = newHealth.clamp(0.0, maxHealth);
      healthNotifier.value = clampedHealth;
      onHealthChanged(clampedHealth);
    } finally {
      _isUpdatingHealth = false;
    }
  }

  @override
  void onMount() {
    super.onMount();
    // Ensure initial health is set
    onHealthChanged(healthNotifier.value);
    print('🎯 Boss mounted - Initial health: ${healthNotifier.value}');
  }

  @override
  void applyStaggerVisuals() {
    // Load and play stagger animation
    gameRef
        .loadSpriteAnimation(
      'boss1_stagger.png',
      SpriteAnimationData.sequenced(
        amount: 2, // 2 frame animation
        textureSize: Vector2(128, 128), // Adjust to match your sprite size
        stepTime: 0.2, // Fast blinking effect
        loop: true,
      ),
    )
        .then((staggerAnimation) {
      animation = staggerAnimation;

      // Also add red tint
      add(ColorEffect(
        const Color(0xFFFF0000),
        EffectController(duration: 5.0, reverseDuration: 5.0),
      ));
    });
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
              damage: 10,
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
        Vector2 velocity = Vector2(cos(angle), sin(angle)) * 400;

        final bossProjectile = Projectile.bossProjectile(
          damage: 10, // Example damage
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
    print('🔄 Beginning return to normal sequence');
    isFading = false;
    attackCooldown = originalAttackCooldown;
    speed = originalSpeed;

    // Fade back in slowly
    add(OpacityEffect.to(
      1.0,
      EffectController(duration: 2.0, curve: Curves.easeIn),
      onComplete: () {
        isTargetable = true;
        gameRef.player.enableShooting();
        print('✅ Boss fully returned to normal state');
        add(RectangleHitbox());
      },
    ));
  }

  @override
  void onRemove() {
    _playerStandingTimer?.stop();
    _projectileTimer?.stop();
    _warningCircle?.removeFromParent();
    _coneTimer?.stop();
    _pullbackTimer?.stop();
    _pullingProjectiles.clear();
    super.onRemove();
  }

  // COMBINE triggerX165Mechanics and _enterFadingPhase
  void _enterFadingPhase() {
    print('🔥 _enterFadingPhase called');

    if (hasTriggeredX165) {
      print('⛔ _enterFadingPhase: Already triggered, returning');
      return;
    }

    hasTriggeredX165 = true; // Set this FIRST to prevent re-entry
    isFading = true;

    if (isStaggered) {
      print('⛔ _enterFadingPhase: Is staggered, delaying');
      Future.delayed(Duration(milliseconds: 500), () {
        if (isMounted && !isStaggered && !isFading) {
          print('🔄 _enterFadingPhase: Retrying after stagger');
          _enterFadingPhase(); // Recursive call
        }
      });
      return;
    }

    print('🔥 X165 PHASE START');
    pauseNormalAttackPattern();
    removeWhere((component) => component is RectangleHitbox);

    // Step 1: Fade Out
    isTargetable = false;
    gameRef.player.disableShooting();

    add(OpacityEffect.to(
      0.0,
      EffectController(duration: 2.0),
      onComplete: () {
        print('🔄 Fade out complete');
        if (!isMounted) {
          print('❌ _enterFadingPhase: Not mounted after fade, returning');
          return;
        }

        opacity = 0;
        position = Vector2(-9999, -9999);

        // Step 2: Wait 4 seconds
        print('⌛ Starting 4s delay');
        Future.delayed(const Duration(seconds: 4), () {
          if (!isMounted) {
            print('❌ _enterFadingPhase: Not mounted after delay, returning');
            return;
          }

          // Step 4: Begin Teleport Phase
          print('🎯 Starting teleport phase');
          _teleportShootRemainingTime = 15;
          _startTeleportAndShootPhase();
        });
      },
    ));
  }

  void _startTeleportAndShootPhase() {
    if (isStaggered) {
      print('⏳ Delaying teleport phase - Boss is staggered');
      Future.delayed(Duration(seconds: 1), () {
        if (isMounted && !isStaggered) {
          _startTeleportAndShootPhase();
        }
      });
      return;
    }

    print('👻 Starting teleport and shoot phase');
    _teleportOutsidePlayerRange();
    _teleportShootRemainingTime = 15;
    _timeSinceLastTeleportShoot = 0;

    Future.delayed(Duration(seconds: 15), () {
      if (isMounted && !isStaggered) {
        print('⚡ Teleport phase complete, returning to normal');
        _returnToNormalState();
      }
    });
  }

  void triggerX195Mechanics() {
    //No changes required
    print('🔥 Boss at X195 - Triggering new mechanics!');
    // Increase attack speed
    attackCooldown *= 0.8;
    // Add more mechanics as needed
  }

  void triggerX190Mechanics() {
    print('🔥 Boss at X190 - Starting alternate attack pattern');
    alternatePattern = true;

    // Increase attack speed
    attackCooldown = originalAttackCooldown * 0.7; // 30% faster attacks

    // Start shooting in alternating patterns
    _startAlternateAttackPattern();
  }

  void _startAlternateAttackPattern() {
    print('⚔️ Starting alternate attack pattern');
    _isExecutingTargetedAttack = false;

    // Reset attack timers
    timeSinceLastAttack = 0;
    attackCount = 0;

    // Randomly choose an attack pattern
    int patternChoice = Random().nextInt(3); // 0-2
    print('🎲 Chose attack pattern: $patternChoice');

    switch (patternChoice) {
      case 0:
        _shootBurstPattern();
        break;
      case 1:
        _shootSpiralPattern();
        break;
      case 2:
        _shootCrossPattern();
        break;
    }
  }

  void _shootBurstPattern() {
    if (!isMounted || isStaggered) return;

    // Shoot in a circular burst pattern
    for (int i = 0; i < 8; i++) {
      double angle = (i * 2 * pi) / 8;
      Vector2 direction = Vector2(cos(angle), sin(angle));

      final projectile = Projectile.bossProjectile(
        damage: 15,
        velocity: direction * 400,
        color: Colors.red,
      )
        ..position = position.clone()
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
    }
  }

  void _shootSpiralPattern() {
    if (!isMounted || isStaggered) return;

    // Shoot in a spiral pattern
    for (int i = 0; i < 6; i++) {
      double angle = (attackCount * pi / 8) + (i * 2 * pi / 6);
      Vector2 direction = Vector2(cos(angle), sin(angle));

      final projectile = Projectile.bossProjectile(
        damage: 15,
        velocity: direction * 350,
        color: Colors.orange,
      )
        ..position = position.clone()
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
    }
  }

  void _shootCrossPattern() {
    if (!isMounted || isStaggered) return;

    // Shoot in a cross pattern
    for (int i = 0; i < 4; i++) {
      double angle = (i * pi / 2) + (attackCount * pi / 8);
      Vector2 direction = Vector2(cos(angle), sin(angle));

      // Shoot two projectiles in each direction
      for (double speed in [300.0, 450.0]) {
        final projectile = Projectile.bossProjectile(
          damage: 15,
          velocity: direction * speed,
          color: Colors.purple,
        )
          ..position = position.clone()
          ..size = Vector2.all(40)
          ..anchor = Anchor.center;

        gameRef.add(projectile);
      }
    }
  }

  void triggerX150Mechanics() {
    print('💫 Boss at X150 - Creating orbital trap!');
    position = Vector2(1280 / 2, (1280 / 2) - 100); // Center position
    createOrbitalAttack(
        projectileCount: 32,
        radius: 400.0,
        speed: 3.0,
        projectileDamage: 9999.0);
    // Remove the automatic release - keep orbital attack until death
  }

  void createOrbitalAttack({
    int projectileCount = 16,
    double radius = 400.0,
    double speed = 3.0,
    double projectileDamage = 9999.0,
  }) {
    _isPerformingOrbitalAttack = true;
    _baseRadius = radius; // Store base radius
    _orbitalRadius = radius;

    print('🎯 Creating orbital attack - Current position: $position');

    // Clear any existing orbital projectiles
    for (var proj in _orbitalProjectiles) {
      proj.removeFromParent();
    }
    _orbitalProjectiles.clear();

    // Position slightly higher to ensure bottom of circle is visible
    position = Vector2(1280 / 2, (1280 / 2) - 100);
    anchor = Anchor.center;
    _storedSpeed = this.speed;
    this.speed = 0;

    _orbitalSpeed = speed;
    _orbitalAngle = 0.0;
    _patternTimer = 0;
    _currentPattern = OrbitalPattern.NORMAL;

    // Create orbital projectiles
    for (int i = 0; i < projectileCount; i++) {
      double angle = (i * 2 * pi) / projectileCount;
      Vector2 offset = Vector2(
        cos(angle) * radius,
        sin(angle) * radius,
      );

      final projectile = Projectile.bossProjectile(
        damage: projectileDamage.toInt(),
        velocity: Vector2.zero(),
        color: Colors.purple,
      )
        ..position = position + offset
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
      _orbitalProjectiles.add(projectile);
    }
  }

  void updateOrbitalProjectiles(double dt) {
    if (_orbitalProjectiles.isEmpty) return;

    _orbitalAngle += _orbitalSpeed * dt * 2 * pi;

    for (int i = 0; i < _orbitalProjectiles.length; i++) {
      var projectile = _orbitalProjectiles[i];
      if (!projectile.isMounted) {
        _orbitalProjectiles.removeAt(i);
        i--;
        continue;
      }

      // Normal orbital movement
      double angle = _orbitalAngle + (i * 2 * pi) / _orbitalProjectiles.length;
      Vector2 newOffset = Vector2(
        cos(angle) * _orbitalRadius,
        sin(angle) * _orbitalRadius,
      );
      projectile.position = position + newOffset;
    }
  }

  void releaseOrbitalProjectiles() {
    if (!_isPerformingOrbitalAttack) return;

    for (var projectile in _orbitalProjectiles) {
      if (!projectile.isMounted) continue;

      Vector2 direction = (projectile.position - position).normalized();
      projectile.velocity = direction * 500;
    }

    _orbitalProjectiles.clear();
    _isPerformingOrbitalAttack = false;
    speed = _storedSpeed; // Restore original speed
  }

  @override
  void applyStaggerDamage(int damage, {bool isCritical = false}) {
    // Apply stagger damage normally without X150 check
    takeDamage(damage.toDouble(), isCritical: isCritical);

    // Apply normal stagger effects
    super.applyStaggerDamage(damage, isCritical: isCritical);
  }

  @override
  void triggerStagger() {
    // Remove X150 immunity check
    super.triggerStagger();

    // Reset animation after stagger duration
    Future.delayed(Duration(seconds: staggerDuration.toInt()), () {
      if (isMounted) {
        print('🔄 Resetting to idle animation after stagger');
        animation = idleAnimation;
      }
    });
  }

  void triggerX120Mechanics() {
    print('🔥 Boss at X120 - Adding cone attacks!');
    // Remove this line since we want to allow attacks during orbital phase
    // pauseNormalAttackPattern();
    applyStaggerVisuals();

    _coneTimer = Timer(
      4, // Every 4 seconds
      onTick: () {
        print('⏰ Cone timer tick!');
        if (healthBar.currentSegment > 100 || !isMounted) {
          print(
              '❌ Stopping cone timer - health: ${healthBar.currentSegment}, mounted: $isMounted');
          _coneTimer?.stop();
          return;
        }

        // Use the orbital attack position for cone attacks
        Vector2 attackPosition = _isPerformingOrbitalAttack
            ? Vector2(1280 / 2, (1280 / 2) - 100)
            : // Use orbital position
            position; // Use current position

        // Random angle for the cone direction (in radians)
        final randomAngle = Random().nextDouble() * 2 * pi;
        print('📐 Creating cone at angle: ${randomAngle * 180 / pi}°');

        // First show the warning area
        createWarningCone(
          projectileCount: 8,
          radius: 100.0,
          angleSpread: pi / 4,
          baseAngle: randomAngle,
          position: attackPosition, // Pass position
        );

        // After 2 seconds, create the actual damaging projectiles
        Future.delayed(const Duration(seconds: 2), () {
          if (isMounted) {
            print('🎯 Creating damaging cone projectiles');
            createConeAttack(
              projectileCount: 8,
              radius: 100.0,
              angleSpread: pi / 4,
              baseAngle: randomAngle,
              speed: 4.0,
              projectileDamage: 20.0,
              position: attackPosition, // Pass position
            );
          }
        });
      },
      repeat: true,
    );

    // Start the timer
    print('▶️ Starting cone timer');
    _coneTimer?.start();
  }

  void createWarningCone({
    required int projectileCount,
    required double radius,
    required double angleSpread,
    required double baseAngle,
    required Vector2 position, // Add position parameter
  }) {
    final angleStep = angleSpread / (projectileCount - 1);
    final startAngle = baseAngle - (angleSpread / 2);

    for (var i = 0; i < projectileCount; i++) {
      final angle = startAngle + (angleStep * i);
      final direction = Vector2(cos(angle), sin(angle));

      final warningProjectile = Projectile.warning(
        direction: direction,
        radius: radius,
        duration: 2.0,
        warningColor: Colors.red.withOpacity(0.3),
      )
        ..position = position.clone() // Use passed position
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(warningProjectile);
    }
  }

  void createConeAttack({
    required int projectileCount,
    required double radius,
    required double angleSpread,
    required double baseAngle,
    required double speed,
    required double projectileDamage,
    required Vector2 position, // Add position parameter
  }) {
    final angleStep = angleSpread / (projectileCount - 1);
    final startAngle = baseAngle - (angleSpread / 2);

    for (var i = 0; i < projectileCount; i++) {
      final angle = startAngle + (angleStep * i);
      final direction = Vector2(cos(angle), sin(angle));

      final projectile = Projectile.bossProjectile(
        damage: projectileDamage.toInt(),
        velocity: direction * speed * 100,
        color: Colors.red,
      )
        ..position = position.clone() // Use passed position
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
    }
  }

  void triggerX80Mechanics() {
    // Increase projectile speed and reduce cooldown
    attackCooldown *= 0.7; // 30% faster attacks
    _orbitalSpeed *= 5.3; // 30% faster projectiles
    print(
        '🚀 Attack speed increased - Cooldown: $attackCooldown, Projectile Speed: $_orbitalSpeed');
  }

  void _dropBossLoot() {
    print('💎 Rolling for Umbrathos loot');

    final droppedItem = LootTable.getRandomLoot();
    if (droppedItem != null) {
      print('🎁 Umbrathos dropped: ${droppedItem.name}!');
      gameRef.player.collectItem(droppedItem);

      gameRef.lootNotificationBar.showNotification(
          'Obtained: ${droppedItem.name}', droppedItem.rarity);
    } else {
      print('😢 No item dropped this time.');
    }
  }

  void _spawnLootBox() {
    print('💎 Rolling for boss loot');
    final loot = LootTable.getRandomLoot();
    if (loot != null) {
      print('🎁 Creating loot box with: ${loot.name}');
      final lootBox = LootBox(items: [loot]);
      lootBox.position = position.clone();
      gameRef.add(lootBox);
      print('✨ Loot box spawned at: ${lootBox.position}');
    } else {
      print('❌ No loot generated for boss');
    }
  }

  @override
  void die() {
    print('💀 Umbrathos is dying...');

    // Stop any active attacks
    _endOrbitalAttack();

    // Remove boss from the game
    if (isMounted) {
      print('🗑️ Removing Umbrathos...');
      removeFromParent();
    }

    // ✅ Remove health bar
    if (gameRef.isMounted) {
      print('🗑️ Removing health bar...');
      gameRef.overlays.remove('bossHealthBar');
    }

    // ✅ Remove stagger bar if it exists
    if (staggerBar.isMounted) {
      print('🗑️ Removing stagger bar...');
      staggerBar.removeFromParent();
    }

    // ✅ Clear all boss projectiles
    for (var projectile in gameRef.children.whereType<Projectile>()) {
      if (projectile.isBossProjectile) {
        print('🗑️ Removing boss projectile...');
        projectile.removeFromParent();
      }
    }

    // ✅ Drop loot box after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _spawnLootBox();
    });

    // ✅ Victory after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (gameRef.isMounted) {
        print('🏆 Victory sequence triggered...');
        gameRef.victory();
      }
    });
  }
}
