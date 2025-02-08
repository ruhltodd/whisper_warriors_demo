import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart'; // Import for VoidCallback
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';

class BaseEnemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  double _baseSpeed; // ✅ Store base speed internally
  int health;
  VoidCallback? onRemoveCallback;

  double timeSinceLastDamageNumber = 0.0;
  final double damageNumberInterval = 0.5;

  bool hasExploded = false; // ✅ Prevent multiple explosions
  bool hasDroppedItem = false; // ✅ Prevent multiple drops

  BaseEnemy({
    required this.player,
    required this.health,
    required double speed, // ✅ Accept initial speed as parameter
    required Vector2 size,
  })  : _baseSpeed = speed,
        super(size: size, anchor: Anchor.center);

  double get speed => _baseSpeed; // ✅ Now `speed` can be modified in subclasses
  set speed(double value) => _baseSpeed = value; // ✅ Al
  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastDamageNumber += dt;

    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    if ((player.position - position).length < 10) {
      player.takeDamage(1);
      removeFromParent();
    }
  }

  // ✅ Updated to handle Critical Hits
  void takeDamage(int baseDamage, {bool isCritical = false}) {
    // ✅ If the attack doesn't specify a crit (like abilities), roll for a crit chance
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }

    // ✅ Apply critical multiplier if crit occurs
    int finalDamage =
        isCritical ? (baseDamage * player.critMultiplier).toInt() : baseDamage;

    health -= finalDamage;

    // ✅ Ensure at least one damage number appears per hit
    if (timeSinceLastDamageNumber >= damageNumberInterval ||
        timeSinceLastDamageNumber == 0.0) {
      final damageNumber = DamageNumber(
        finalDamage,
        position.clone() + Vector2(0, -10),
        isCritical: isCritical, // ✅ Flag critical damage
      );
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0.0; // ✅ Reset the timer
    }

    // ✅ Handle Death
    if (health <= 0) {
      die();
    }
  }

  void die() {
    if (!hasExploded && gameRef.player.hasAbility<SoulFracture>()) {
      hasExploded = true;
      gameRef.add(Explosion(position)); // ✅ Explosion animation
      gameRef.player.triggerExplosion(position);
    }

    if (!hasDroppedItem) {
      hasDroppedItem = true;
      final blueCoinItem = BlueCoin();
      final drop = DropItem(item: blueCoinItem)..position = position.clone();
      gameRef.add(drop);
    }

    removeFromParent(); // ✅ Ensure the enemy is removed from the game world
  }
}
