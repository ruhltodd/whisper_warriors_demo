import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart'; // Import for VoidCallback
import 'package:whisper_warriors/game/ai/wave2Enemy.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/ui/shadoweffect.dart';

abstract class BaseEnemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame>, ShadowEffectMixin {
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

  void takeDamage(double damage, {bool isCritical = false}) {
    if (health <= 0) return;
    // Apply damage
    health -= damage.toInt();

    // Show damage number
    if (timeSinceLastDamageNumber >= damageNumberInterval) {
      final damageNumber = DamageNumber(
        damage.toInt(),
        position.clone(),
        isCritical: isCritical,
      );
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0;
    }
    // Play hit animation
    // TODO: Implement hit animation system
    // playAnimation('hit'); // Removed since method doesn't exist yet

    // Check for death
    if (health <= 0) {
      die();
    }

    print('💥 Enemy took $damage damage. Health: $health');
  }

  void die() {
    if (!hasExploded && gameRef.player.hasAbility<SoulFracture>()) {
      hasExploded = true;
      gameRef.add(Explosion(position)); // ✅ Explosion animation
      gameRef.player.triggerExplosion(position);
    }

    if (!hasDroppedItem) {
      hasDroppedItem = true;
      final coinItem = this is Wave2Enemy ? GreenCoin() : BlueCoin();
      final drop = DropItem(item: coinItem)..position = position.clone();

      gameRef.add(drop);
    }

    // ✅ Grant XP for defeating this enemy
    int xpEarned = this is Wave2Enemy ? 160 : 80; // ✅ Green Coin = Double XP
    PlayerProgressManager.addXp(xpEarned);
    print("⚔️ Enemy Defeated! +$xpEarned XP");

    // ✅ Notify SpawnController that an enemy has been removed
    if (gameRef.spawnController != null) {
      gameRef.spawnController!.decreaseEnemyCount();
    }

    removeFromParent(); // ✅ Ensure the enemy is removed from the game world
  }

  @override
  void render(Canvas canvas) {
    renderWithShadow(canvas);
  }
}
