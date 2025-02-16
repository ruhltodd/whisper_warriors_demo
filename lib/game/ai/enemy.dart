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
  double _baseSpeed;
  int _baseHealth; // Store base health
  int health;
  VoidCallback? onRemoveCallback;

  double timeSinceLastDamageNumber = 0.0;
  final double damageNumberInterval = 0.5;

  bool hasExploded = false;
  bool hasDroppedItem = false;

  BaseEnemy({
    required this.player,
    required int health,
    required double speed,
    required Vector2 size,
  })  : _baseSpeed = speed,
        _baseHealth = health,
        health = health, // Will be scaled in onLoad
        super(size: size, anchor: Anchor.center);

  double get speed => _baseSpeed;
  set speed(double value) => _baseSpeed = value;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Scale health with enemy scaling
    double enemyScaling = PlayerProgressManager.getEnemyScaling();
    health = (_baseHealth * enemyScaling).round();

    print('🔄 Enemy scaled with spirit level: ${enemyScaling}x');
    print('💪 Base Health: $_baseHealth → Scaled Health: $health');
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastDamageNumber += dt;

    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    if ((player.position - position).length < 10) {
      double enemyScaling = PlayerProgressManager.getEnemyScaling();
      int scaledDamage = (1 * enemyScaling).round();
      player.takeDamage(scaledDamage.toDouble());
      removeFromParent();
    }
  }

  void takeDamage(double amount,
      {bool isCritical = false, bool isEchoed = false}) {
    if (health <= 0) return;

    // Convert damage to int for health calculation
    int damageAmount = amount.round();
    health -= damageAmount;

    // Add damage number display
    // Show damage number
    if (timeSinceLastDamageNumber >= damageNumberInterval) {
      final damageNumber = DamageNumber(
        damageAmount,
        position.clone(),
        isCritical: isCritical,
      );
      gameRef.add(damageNumber);
      timeSinceLastDamageNumber = 0;
    }

    print(
        '💥 Enemy took $damageAmount damage${isCritical ? " (CRIT!)" : ""}${isEchoed ? " (Echo)" : ""}. Health: $health');

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
      final coinItem = this is Wave2Enemy ? GreenCoin() : BlueCoin();
      final drop = DropItem(item: coinItem)..position = position.clone();

      gameRef.add(drop);
    }

    // ✅ Grant XP for defeating this enemy
    int xpEarned = this is Wave2Enemy ? 160 : 80; // ✅ Green Coin = Double XP
    PlayerProgressManager.gainSpiritExp(xpEarned.toDouble());
    print("⚔️ Enemy Defeated! +$xpEarned XP");

    // ✅ Notify SpawnController that an enemy has been removed
    if (gameRef.spawnController != null) {
      gameRef.spawnController!.decreaseEnemyCount();
    }

    removeFromParent(); // ✅ Ensure the enemy is removed from the game world
  }
}
