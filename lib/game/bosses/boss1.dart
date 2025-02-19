import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/bosses/bosshealthbar.dart';
import 'staggerable.dart';
import 'package:flame/timer.dart';
import 'dart:async'; // Add this import at the top

class Boss1 extends BaseEnemy with Staggerable {
  final ValueNotifier<double> healthNotifier;
  bool enraged = false;
  bool isFading = false;
  // Removed _startTeleportation (it's redundant)
  bool hasTriggeredX195 = false;
  bool hasTriggeredX190 = false;
  bool hasTriggeredX165 = false;
  bool hasTriggeredX150 = false;
  bool hasTriggeredX100 = false;
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
  bool _isLockedInPlace = false; // Add this flag
  double _storedSpeed = 0.0; // Add this to store original speed

  Timer? _coneTimer; // Add timer as class property

  bool _isUpdatingHealth = false; // Add flag to prevent recursive updates

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
    if (_isUpdatingHealth) return;
    super.update(dt);

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
        '🔍 Current Segment: ${healthBar.currentSegment}, X100 Triggered: $hasTriggeredX100');

    // Allow X100 to trigger while X150 is active
    if (currentSegment <= 100 && !hasTriggeredX100) {
      print('✅ Health below 100');
      hasTriggeredX100 = true;
      triggerX100Mechanics();
    }
  }

  void setLanded(bool value) {
    _hasLanded = value;
    print('🛬 Boss landed state changed to: $_hasLanded');
  }

  void _updateMovement(double dt) {
    if (!isMounted) return;

    // Debug current state
    print(
        '🔄 Movement Update - Landed: $_hasLanded, Locked: $_isLockedInPlace, Fading: $isFading');

    // Early return if locked or not landed
    if (!_hasLanded || _isLockedInPlace) {
      // Removed healthBar.currentSegment check
      print(
          '🚫 Movement blocked - Landed: $_hasLanded, Locked: $_isLockedInPlace');
      animation = idleAnimation;
      return;
    }

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
        damage: 1, //changed from 15 to 1 but change back to 15 for final
        velocity: projectileVelocity,
      )
        ..position = spawnPosition
        ..size = Vector2(50, 50)
        ..anchor = Anchor.center;

      gameRef.add(bossProjectile);
    }
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
    print('🔄 Beginning return to normal sequence');
    isFading = false;
    attackCooldown = originalAttackCooldown;
    speed = originalSpeed;

    // Remove existing effects
    removeAll(children.whereType<ColorEffect>());

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

    // Step 1: Blue Glow
    add(ColorEffect(
      const Color(0xFF00BBFF),
      EffectController(duration: 3.0),
      onComplete: () {
        print('💫 Blue glow complete');
        if (!isMounted) {
          print('❌ _enterFadingPhase: Not mounted after glow, returning');
          return;
        }

        // Step 2: Fade Out
        isTargetable = false;
        gameRef.player.disableShooting();

        add(OpacityEffect.to(
          0.0,
          EffectController(duration: 2.0),
          onComplete: () {
            print('�️ Fade out complete');
            if (!isMounted) {
              print('❌ _enterFadingPhase: Not mounted after fade, returning');
              return;
            }

            opacity = 0;
            position = Vector2(-9999, -9999);

            // Step 3: Wait 4 seconds
            print('⌛ Starting 4s delay');
            Future.delayed(const Duration(seconds: 4), () {
              if (!isMounted) {
                print(
                    '❌ _enterFadingPhase: Not mounted after delay, returning');
                return;
              }

              // Step 4: Begin Teleport Phase
              print('🎯 Starting teleport phase');
              _teleportShootRemainingTime = 15;
              _startTeleportAndShootPhase();
            });
          },
        ));
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
    //No changes required
    print('💥 Boss at X190 - Triggering rage mechanics!');
    // Increase projectile count
    alternatePattern = true;
    // Add more mechanics as needed
  }

  void triggerX150Mechanics() {
    print('💫 Boss at X150 - Creating orbital trap!');
    _isLockedInPlace = true; // Lock the boss in place
    position = Vector2(1280 / 2, (1280 / 2) - 100); // Center position
    createOrbitalAttack(
        projectileCount: 32, radius: 400.0, speed: 3.0, projectileDamage: 25.0);
    pauseNormalAttackPattern();
    applyStaggerVisuals();
    // Remove the automatic release - keep orbital attack until death
  }

  void createOrbitalAttack({
    int projectileCount = 16,
    double radius = 400.0,
    double speed = 3.0,
    double projectileDamage = 25.0,
  }) {
    _isPerformingOrbitalAttack = true;

    print('🎯 Creating orbital attack - Current position: $position');

    // Clear any existing orbital projectiles
    for (var proj in _orbitalProjectiles) {
      proj.removeFromParent();
    }
    _orbitalProjectiles.clear();

    // Position slightly higher to ensure bottom of circle is visible
    position = Vector2(1280 / 2, (1280 / 2) - 100);
    anchor = Anchor.center;
    _storedSpeed = speed; // Store original speed
    speed = 0; // Stop movement

    print('🎯 After setting orbital position: $position');

    _orbitalRadius = radius;
    _orbitalSpeed = speed;
    _orbitalAngle = 0.0;

    // Create projectiles in a circle
    for (int i = 0; i < projectileCount; i++) {
      double angle = (i * 2 * pi) / projectileCount;
      Vector2 offset = Vector2(
        cos(angle) * _orbitalRadius,
        sin(angle) * _orbitalRadius,
      );

      final projectile = Projectile.bossProjectile(
        damage: projectileDamage.toInt(),
        velocity: Vector2.zero(),
      )
        ..position = position + offset
        ..size = Vector2(50, 50)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
      _orbitalProjectiles.add(projectile);
    }
  }

  void updateOrbitalProjectiles(double dt) {
    if (_orbitalProjectiles.isEmpty) return;

    _orbitalAngle += _orbitalSpeed * dt * 2 * pi; // Convert to radians

    for (int i = 0; i < _orbitalProjectiles.length; i++) {
      var projectile = _orbitalProjectiles[i];
      if (!projectile.isMounted) {
        _orbitalProjectiles.removeAt(i);
        i--;
        continue;
      }

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
    // Double check X150 immunity
    if (healthBar.currentSegment <= 150) {
      print('🛡️ Boss immune to stagger trigger at X150');
      return;
    }

    super.triggerStagger();

    // Reset animation after stagger duration
    Future.delayed(Duration(seconds: staggerDuration.toInt()), () {
      if (isMounted) {
        print('🔄 Resetting to idle animation after stagger');
        animation = idleAnimation;
      }
    });
  }

  void triggerX100Mechanics() {
    print('🔥 Boss at X100 - Adding cone attacks!');
    // Don't change position or lock state here - maintain X150 position
    pauseNormalAttackPattern();

    _coneTimer = Timer(
      4,
      onTick: () {
        print('⏰ Cone timer tick!');
        if (healthBar.currentSegment > 100 || !isMounted) {
          print(
              '❌ Stopping cone timer - health: ${healthBar.currentSegment}, mounted: $isMounted');
          _coneTimer?.stop();
          return;
        }

        // Random angle for the cone direction (in radians)
        final randomAngle = Random().nextDouble() * 2 * pi;
        print('📐 Creating cone at angle: ${randomAngle * 180 / pi}°');

        // First show the warning area
        createWarningCone(
          projectileCount: 8,
          radius: 100.0,
          angleSpread: pi / 4,
          baseAngle: randomAngle,
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
              projectileDamage: 30.0,
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
        warningColor: Colors.red.withOpacity(0.3), // Now optional
      )
        ..position = position.clone()
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
  }) {
    final angleStep = angleSpread / (projectileCount - 1);
    final startAngle = baseAngle - (angleSpread / 2);

    for (var i = 0; i < projectileCount; i++) {
      final angle = startAngle + (angleStep * i);
      final direction = Vector2(cos(angle), sin(angle));

      final projectile = Projectile.bossProjectile(
        damage: projectileDamage.toInt(),
        velocity: direction * speed * 100,
        color: Colors.red, // Changed from color to projectileColor
      )
        ..position = position.clone()
        ..size = Vector2.all(40)
        ..anchor = Anchor.center;

      gameRef.add(projectile);
    }
  }
}
