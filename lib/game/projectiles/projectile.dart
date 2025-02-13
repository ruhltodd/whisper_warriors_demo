import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/ai/wave2Enemy.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';

class Projectile extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;
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

  // 🔹 **General Constructor**
  Projectile({
    required this.damage,
    required this.velocity,
    this.isBossProjectile = false,
    this.maxRange = 800,
    this.onHit, // ✅ Now optional (for abilities like Cursed Echo)
    this.player, // ✅ Include player reference if available
    this.isCritical = false, // Add this parameter with default value
  }) {
    shouldPierce = player?.hasItem("Umbral Fang") ??
        false; // ✅ Always check if Umbral Fang is equipped
  } // Adjust size as needed

  // 🔹 **Named Constructor for Player**
  Projectile.playerProjectile({
    required int damage,
    required Vector2 velocity,
    required Player player, // ✅ Ensure player is passed
    void Function(BaseEnemy)? onHit, // ✅ Pass `onHit` for abilities
  }) : this(
          damage: damage,
          velocity: velocity,
          maxRange: 800,
          isBossProjectile: false,
          onHit: onHit, // ✅ Ensure `onHit` is passed
          player: player, // ✅ Assign player
          isCritical: false, // Add this parameter with default value
        );

  // 🔹 **Named Constructor for Boss**
  Projectile.bossProjectile({required int damage, required Vector2 velocity})
      : this(
          damage: damage,
          velocity: velocity,
          maxRange: double.infinity, // ✅ Boss projectiles should go forever
          isBossProjectile: true,
          isCritical: false, // Add this parameter with default value
        );

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
          stepTime: 0.3, // ✅ Adjust animation speed
          textureSize: Vector2(80, 80), // ✅ Each frame size
          loop: true, // ✅ Keeps looping while projectile is active
        ),
      );
    } else {
      final normalSprite = await gameRef.loadSprite('projectile_normal.png');

      // ✅ Single-frame animation for normal projectiles
      animation = SpriteAnimation.spriteList(
        [normalSprite],
        stepTime: double.infinity, // ✅ Static sprite, never loops
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

    // ✅ Ensure player projectiles don't collide with the player
    if (!isBossProjectile && other is Player) {
      return;
    }

    // ✅ Ensure player projectiles hit enemies
    if (!isBossProjectile && other is BaseEnemy) {
      other.takeDamage(damage);

      if (!shouldPierce) {
        removeFromParent();
      }
      return; // ✅ Prevents further execution
    }

    // ✅ Ensure boss projectiles hit the player
    if (isBossProjectile && other is Player) {
      other.takeDamage(damage);
      removeFromParent();
      return;
    }

    // ✅ Ignore other unexpected collisions
  }
}
