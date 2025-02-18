import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/damage/damage_tracker.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';

class Projectile extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final double damage;
  final bool isBossProjectile;
  final double maxRange;
  late Vector2 spawnPosition;
  final void Function(BaseEnemy)? onHit; // ✅ Callback for hit logic
  final Player? player; // ✅ Add player reference
  bool shouldPierce = false; // ✅ Declare before checking conditions
  final List<BaseEnemy> enemiesHit =
      []; // ✅ Track enemies hit by the projectile
  final bool isCritical; // Add this field
  bool hasCollided = false;
  double _distanceTraveled = 0;
  final String abilityName; // Add this field
  final bool isWarning;
  final double? warningDuration;
  final Color? warningColor;
  double _warningTimePassed = 0;

  // 🔹 **General Constructor**
  Projectile({
    required this.damage,
    required this.velocity,
    this.isBossProjectile = false,
    this.maxRange = 800,
    this.onHit, // ✅ Now optional (for abilities like Cursed Echo)
    this.player, // ✅ Include player reference if available
    this.isCritical = false, // Add this parameter with default value
    this.abilityName = 'Basic Attack', // Add default value
    this.isWarning = false,
    this.warningDuration,
    this.warningColor,
  }) {
    shouldPierce = player?.hasItem("Umbral Fang") ??
        false; // ✅ Always check if Umbral Fang is equipped
  } // Adjust size as needed

  // 🔹 **Named Constructor for Player**
  Projectile.playerProjectile({
    required double damage,
    required Vector2 velocity,
    required Player player, // ✅ Ensure player is passed
    void Function(BaseEnemy)? onHit, // ✅ Pass `onHit` for abilities
    String abilityName = 'Basic Attack', // Add parameter
    bool isCritical = false, // Add parameter
  }) : this(
          damage: damage,
          velocity: velocity,
          maxRange: 800,
          isBossProjectile: false,
          onHit: onHit, // ✅ Ensure `onHit` is passed
          player: player, // ✅ Assign player
          abilityName: abilityName,
          isCritical: isCritical,
          isWarning: false,
          warningDuration: null,
          warningColor: null,
        );

  // 🔹 **Named Constructor for Boss**
  Projectile.bossProjectile({
    required int damage,
    required Vector2 velocity,
    Color color = Colors.purple, // Default color if none provided
  }) : this(
          damage: damage.toDouble(),
          velocity: velocity,
          maxRange: double.infinity, // ✅ Boss projectiles should go forever
          isBossProjectile: true,
          isCritical: false, // Add this parameter with default value
          abilityName: 'Basic Attack',
          isWarning: false,
          warningDuration: null,
          warningColor: color,
        );

  // Factory constructor for warning projectiles
  factory Projectile.warning({
    required Vector2 direction,
    required double radius,
    required double duration,
    Color? warningColor, // Made optional with default in constructor
  }) {
    return Projectile(
      velocity: direction * radius,
      damage: 0, // No damage for warning projectiles
      isBossProjectile: false,
      maxRange: 800,
      onHit: null,
      player: null,
      isCritical: false,
      abilityName: 'Warning',
      isWarning: true,
      warningDuration: duration,
      warningColor: warningColor ??
          Colors.red.withOpacity(0.3), // Default color if none provided
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    spawnPosition = position.clone(); // ✅ Track initial position

    if (isBossProjectile) {
      final spriteSheet = await gameRef.images.load('boss_projectile.png');

      // ✅ Assign animation
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4, // ✅ Number of frames
          stepTime: 0.15, // ✅ Adjust animation speed
          textureSize: Vector2(50, 50), // ✅ Each frame size
          loop: true, // ✅ Keeps looping while projectile is active
        ),
      );
    } else {
      final normalSpriteSheet =
          await gameRef.images.load('projectile_normal.png');

      // ✅ Assign animation for normal projectile
      animation = SpriteAnimation.fromFrameData(
        normalSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4, // ✅ Adjust this based on sprite sheet
          stepTime: 0.2, // ✅ Keep consistent with boss projectile
          textureSize: Vector2(50, 50), // ✅ Ensure correct frame size
          loop: true,
        ),
      );
    }

    add(
      RectangleHitbox()
        ..collisionType = CollisionType.active, // ✅ Still hits enemies
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (isWarning) {
      _warningTimePassed += dt;
      if (_warningTimePassed >= (warningDuration ?? 2.0)) {
        removeFromParent();
      }
      return;
    }

    // 🔹 **Remove player projectiles after max range**
    if (!isBossProjectile && (position - spawnPosition).length > maxRange) {
      removeFromParent(); // ✅ Ensures only the projectile is removed
    }

    // 🔹 **Boss Projectiles travel indefinitely**
    if (isBossProjectile &&
        (position.x < -400 ||
            position.x > gameRef.size.x + 400 ||
            position.y < -400 ||
            position.y > gameRef.size.y + 400)) {
      removeFromParent(); // ✅ Ensure only the projectile is removed, not the boss
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (!isBossProjectile && other is Player) {
      return;
    }

    if (!isBossProjectile && other is BaseEnemy) {
      print('💥 Projectile hit enemy! Ability: $abilityName');

      // Use DamageTracker with proper initialization
      if (player != null) {
        print(
            '📊 Recording damage for $abilityName: $damage (Critical: $isCritical)');
        DamageTracker(abilityName)
            .recordDamage(damage.toInt(), isCritical: isCritical);
      } else {
        print('⚠️ No player reference in projectile!');
      }

      other.takeDamage(damage, isCritical: isCritical);

      if (!shouldPierce) {
        removeFromParent();
      }
      return;
    }

    if (isBossProjectile && other is Player) {
      other.takeDamage(damage);
      removeFromParent();
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isWarning) {
      final paint = Paint()
        ..color = warningColor ?? Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, size.x / 2, paint);
    } else {
      super.render(canvas);
    }
  }

  // Add this static factory method
  static Projectile shootFromPlayer({
    required Player player,
    required Vector2 targetPosition,
    required double projectileSpeed,
    required double damage,
    void Function(BaseEnemy)? onHit,
    String abilityName = 'Basic Attack',
  }) {
    bool isCritical = player.isCriticalHit();
    double finalDamage = isCritical ? damage * player.critMultiplier : damage;

    final direction = (targetPosition - player.position).normalized();
    final velocity = direction * projectileSpeed;

    final projectile = Projectile.playerProjectile(
      damage: finalDamage,
      velocity: velocity,
      player: player,
      onHit: onHit,
      abilityName: abilityName,
      isCritical: isCritical,
    )
      ..position = player.position.clone()
      ..size = Vector2(50, 50)
      ..anchor = Anchor.center;

    // Handle Cursed Echo ability
    if (player.hasAbility<CursedEcho>()) {
      print('🔮 Player has Cursed Echo ability');
      double procChance = 0.20; // 20% chance
      if (player.gameRef.random.nextDouble() < procChance) {
        print('✨ Cursed Echo triggered for $abilityName!');
        Future.delayed(Duration(milliseconds: 100), () {
          if (player.isMounted) {
            print('🌟 Creating echo projectile for $abilityName');
            final echoProjectile = Projectile.playerProjectile(
              damage: finalDamage,
              velocity: velocity,
              player: player,
              onHit: (enemy) {
                print('💫 Echo projectile hit! ($abilityName)');
              },
              abilityName:
                  '$abilityName (Echo)', // Mark echo projectiles distinctly
              isCritical: isCritical,
            )
              ..position = player.position.clone()
              ..size = Vector2(50, 50)
              ..anchor = Anchor.center;

            player.gameRef.add(echoProjectile);
            print('✅ Echo projectile added to game');
          } else {
            print('⚠️ Player no longer exists for Cursed Echo');
          }
        });
      } else {
        print(
            '❌ Cursed Echo failed to proc (${(procChance * 100).toInt()}% chance)');
      }
    }

    print('✨ Original projectile created successfully');
    return projectile;
  }
}
