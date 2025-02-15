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
import 'staggerable.dart';
import 'package:flame/timer.dart';
import '../main.dart'; // Import main.dart

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
  late final double maxHealth = 50000;
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
  static const double projectileCooldown =
      0.5; // Shoot every 0.5 seconds while targeting
  bool _isExecutingTargetedAttack = false;
  double currentHealth = 50000;
  bool isDead = false;

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
    anchor = Anchor.center;
    size = Vector2(128, 128);
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0);

    // Initialize standing timer with proper onTick callback
    _playerStandingTimer = Timer(
      standingThreshold,
      onTick: () {
        print('⏰ Standing timer completed!');
        if (!_isExecutingTargetedAttack) {
          print('🎯 Triggering target player');
          targetPlayer();
        } else {
          print('❌ Not targeting - already executing attack');
        }
      },
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Update boss info when spawned
    gameRef.updateBossInfo(
        'Umbrathos, The Fading King', currentHealth, maxHealth);

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

  @override
  void update(double dt) {
    super.update(dt);
    updateStagger(dt);
    updateStaggerBar();

    if (isStaggered) return;

    // Normal attack pattern updates
    if (!_isExecutingTargetedAttack) {
      timeSinceLastAttack += dt;
      timeSinceLastDamageNumber += dt;
      _updateMovement(dt);
      _handleAttacks(dt);

      // Check for player standing still
      final currentPlayerPos = gameRef.player?.position;
      if (currentPlayerPos != null) {
        if (_lastPlayerPosition != null &&
            (_lastPlayerPosition! - currentPlayerPos).length < 1) {
          print(
              '👀 Player standing still for: ${_playerStandingTimer?.current ?? 0}s');

          // Allow the timer to restart after an attack completes
          if (!_isExecutingTargetedAttack) {
            _playerStandingTimer?.update(dt);
          }
        } else {
          print('🏃‍♂️ Player moved, resetting timer');
          _playerStandingTimer?.stop(); // Stop instead of reset
          _playerStandingTimer = Timer(
            standingThreshold,
            onTick: () {
              if (!_isExecutingTargetedAttack) {
                print('🎯 Timer completed - Starting targeted attack');
                targetPlayer();
              }
            },
          );
        }
        _lastPlayerPosition = currentPlayerPos.clone();
      }
    }

    // Update projectile timer if targeting
    if (_isTargetingPlayer && _projectileTimer != null) {
      print('🎯 Updating projectile timer');
      _projectileTimer!.update(dt);
    }
  }

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
  void takeDamage(double amount, {bool isCritical = false}) {
    if (isDead) return;

    currentHealth -= amount;
    print(
        '🗡️ Boss took ${isCritical ? "CRITICAL " : ""}$amount damage. Health: $currentHealth/$maxHealth');

    // Update boss health whenever damage is taken
    gameRef.bossHealthNotifier.value = currentHealth;

    if (currentHealth <= 0 && !isDead) {
      isDead = true;
      // Handle death
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

    // Clear boss info when boss is removed
    gameRef.updateBossInfo('', 0, 0);
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
    if (gameRef.player == null || _isExecutingTargetedAttack) return;

    print('🎯 Starting targeted attack!');

    _isExecutingTargetedAttack = true;
    _isTargetingPlayer = true;

    // Pause normal attack pattern
    pauseNormalAttackPattern();

    // Initialize and start projectile timer
    _projectileTimer = Timer(
      projectileCooldown,
      onTick: () {
        if (gameRef.player != null && _isTargetingPlayer) {
          print('🔥 Firing targeted projectile!');

          // Ensure the direction is correct
          final Vector2 direction =
              (gameRef.player!.position - position).normalized();

          // Validate direction (avoid NaN or zero-length vectors)
          if (direction.length > 0) {
            final bossProjectile = Projectile.bossProjectile(
              damage: 15,
              velocity: direction * 200,
            )
              ..position = position.clone()
              ..size = Vector2.all(40)
              ..anchor = Anchor.center;

            print('➡️ Projectile direction: ${direction.x}, ${direction.y}');
            gameRef.add(bossProjectile);
          } else {
            print('⚠️ Invalid projectile direction! Skipping shot.');
          }
        } else {
          print('❌ Cannot fire: player null or not targeting');
        }
      },
      repeat: true,
    );

    // Explicitly start the timer
    _projectileTimer!.start();
    print('⏱️ Projectile timer started');

    // Stop the targeted attack after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      print('⏱️ Ending targeted attack');
      _stopTargeting();
      _isExecutingTargetedAttack = false;
      resumeNormalAttackPattern();

      // Add cooldown before allowing next targeted attack
      Future.delayed(const Duration(seconds: 5), () {
        if (isMounted) {
          print('🔄 Ready for next targeted attack');
          _isExecutingTargetedAttack = false;
          _isTargetingPlayer = false;
          _playerStandingTimer?.reset();
          _lastPlayerPosition = null;
        }
      });
    });
  }

  void _stopTargeting() {
    print('🛑 Stopping targeting');
    _isTargetingPlayer = false;
    _isExecutingTargetedAttack = false; // Allow new attacks to start

    _playerStandingTimer?.reset();

    // Remove warning circle
    _warningCircle?.removeFromParent();
    _warningCircle = null;

    // Stop and remove the projectile timer
    _projectileTimer?.stop();
    _projectileTimer = null;
  }

  void pauseNormalAttackPattern() {
    // Store the current attack cooldown and set it to a very high number
    // effectively pausing the normal attack pattern
    timeSinceLastAttack = 0;
    attackCooldown = 999999; // Temporarily set to a very high number
  }

  void resumeNormalAttackPattern() {
    // Restore the normal attack cooldown
    attackCooldown = enraged ? 2.8 : 4.0; // Use original cooldown values
    timeSinceLastAttack = 0;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Player) {
      _stopTargeting();
      _isExecutingTargetedAttack = false;
      resumeNormalAttackPattern();
    }
  }

  @override
  void onRemove() {
    _playerStandingTimer?.stop();
    _projectileTimer?.stop();
    _warningCircle?.removeFromParent();
    _warningCircle = null;
    super.onRemove();
  }
}

class BossProjectile extends PositionComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Vector2 direction;
  final double speed = 200;
  final int damage;
  late final Paint _paint;

  BossProjectile({
    required super.position,
    required this.direction,
    required this.damage,
  }) : super(size: Vector2.all(40)) {
    // Match the size of normal projectiles
    // Create a projectile using the same setup as the normal attack
    final bossProjectile = Projectile.bossProjectile(
      damage: damage.toDouble(),
      velocity: direction * speed,
    )
      ..position = Vector2.zero() // Position relative to this component
      ..size = size
      ..anchor = Anchor.center;

    add(bossProjectile);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(direction * speed * dt);

    // Remove if off screen
    if (position.x < 0 ||
        position.x > gameRef.size.x ||
        position.y < 0 ||
        position.y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Player) {
      // Deal damage to player
      gameRef.player?.takeDamage(damage.toDouble());
      // Remove projectile
      removeFromParent();
    }
  }
}
