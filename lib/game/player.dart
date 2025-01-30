import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'healthbar.dart';
import 'main.dart';
import 'enemy.dart';
import 'enemy2.dart';
import 'projectile.dart';
import 'whisperwarrior.dart';
import 'powerup.dart';
import 'healingnumber.dart';

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  double speed = 120;
  double firingCooldown = 1.0;
  double timeSinceLastShot = 1.0;
  int health = 10;
  int maxHealth = 10;
  int level = 1;
  int exp = 0;
  int expToNextLevel = 100;
  HealthBar? healthBar;
  Vector2 joystickDelta = Vector2.zero();
  late WhisperWarrior whisperWarrior;
  Enemy? closestEnemy; // 🔹 Store closest enemy reference
  List<PowerUp> powerUps = []; // Stores acquired power-ups
  double vampiricHealing = 0;
  double damageReduction = 0;
  double magnetRange = 100;
  double blackHoleCooldown = 10;
  Map<PowerUpType, int> powerUpLevels = {}; // ✅ Track power-up levels
  Map<PowerUpType, int> activePowerUps = {}; // ✅ Tracks power-ups for HUD

  Player() : super(size: Vector2(64, 64)) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    healthBar = HealthBar(this);
    gameRef.add(healthBar!);

    whisperWarrior = WhisperWarrior()
      ..size = size.clone()
      ..anchor = Anchor.center
      ..position = position.clone();
    gameRef.add(whisperWarrior);
  }

  void updateJoystick(Vector2 delta) {
    joystickDelta = delta;
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastShot += dt;
    print("🔹 PLAYER MOVEMENT | Pos: $position | HP: $health");

    // 🔹 Run closest enemy check more often
    if (timeSinceLastShot >= 0.2) {
      updateClosestEnemy();
    }

    // Move player using joystick input
    if (joystickDelta.length > 0) {
      position += joystickDelta.normalized() * speed * dt;
      whisperWarrior.playAnimation('walk');
    } else {
      whisperWarrior.playAnimation('idle');
    }

    whisperWarrior.position = position.clone();

    // 🔹 Ensure an enemy is targeted before shooting
    if (timeSinceLastShot >= firingCooldown && closestEnemy != null) {
      shootProjectile();
      timeSinceLastShot = 0.0;
    }

    if (healthBar != null) {
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }
  }

  void updateClosestEnemy() {
    final enemies = gameRef.children.whereType<Enemy>().toList();

    if (enemies.isEmpty) {
      closestEnemy = null;
      return;
    }

    Enemy? newClosest;
    double closestDistance = double.infinity;

    for (final enemy in enemies) {
      final distance = (enemy.position - position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        newClosest = enemy;
      }
    }

    // 🔹 Assign only if it's different
    if (newClosest != closestEnemy) {
      closestEnemy = newClosest;
    }
  }

  void shootProjectile() {
    print("🔹 SHOOTING ATTEMPT");

    whisperWarrior.playAnimation('idle'); // Play attack animation

    // 🔹 Define attack range
    const double attackRange = 300.0;
    const double rangeMargin = 50.0; // Allow slight randomness in targeting
    const double enemy2RangeBoost = 20.0; // Increase hit detection

    // 🔹 Get list of nearby enemies (Includes Enemy & Enemy2)
    final List<PositionComponent> enemies = gameRef.children
        .whereType<
            PositionComponent>() // ✅ Ensures we get only PositionComponents
        .where(
            (entity) => entity is Enemy || entity is Enemy2) // ✅ Filter enemies
        .toList();

    if (enemies.isEmpty) {
      print("❌ NO ENEMIES TO SHOOT!");
      return;
    }

    // 🔹 Sort enemies by distance
    enemies.sort((a, b) => (a.position - position).length.compareTo(
          (b.position - position).length,
        ));
    print("✅ ENEMIES FOUND: ${enemies.length}");

    // 🔹 Get the closest enemy's distance
    double closestDistance = (enemies.first.position - position).length;

    // 🔹 Filter for enemies within a close range margin
    List<PositionComponent> closeEnemies = enemies
        .where((enemy) =>
            (enemy.position - position).length <= closestDistance + rangeMargin)
        .toList();

    // 🔹 Prioritize enemies in the player's **facing direction**
    closeEnemies.sort((a, b) {
      final double angleA =
          joystickDelta.angleTo((a.position - position).normalized());
      final double angleB =
          joystickDelta.angleTo((b.position - position).normalized());

      return angleA
          .abs()
          .compareTo(angleB.abs()); // Lower angle difference = better target
    });

    // 🔹 Pick a random enemy from the top 2 closest and in direction
    final PositionComponent targetEnemy =
        (closeEnemies.take(2).toList()..shuffle()).first;

    // 🔹 Fire projectile at chosen enemy
    final direction = (targetEnemy.position - position).normalized();

    final projectile = Projectile(damage: damage)
      ..position = position.clone()
      ..size = Vector2(10, 10)
      ..anchor = Anchor.center
      ..velocity = direction * 300;

    gameRef.add(projectile);
    print("🚀 PROJECTILE FIRED!");
  }

  int get damage => 1 + (level - 1) * 1;

  void gainExperience(int amount) {
    exp += amount;
    if (exp >= expToNextLevel) {
      levelUp();
    }
    gameRef.experienceBar.updateExperience(exp, expToNextLevel, level);
  }

  void levelUp() {
    level++;
    exp -= expToNextLevel;
    expToNextLevel = (expToNextLevel * 1.5).toInt();
    int oldMaxHealth = maxHealth;
    maxHealth = (maxHealth * 1.2).toInt();

    health = (health / oldMaxHealth * maxHealth).toInt().clamp(1, maxHealth);

    // Adjust current health proportionally to prevent full restore
    healthBar?.updateHealth(health, maxHealth);
    gameRef.showPowerUpSelection();
    gameRef.checkLevelUpScaling();
  }

  void takeDamage(int damage) {
    health -= damage;
    whisperWarrior.playAnimation('hit');
    if (health <= 0) {
      whisperWarrior.playAnimation('death');
      removeFromParent();
      healthBar?.removeFromParent();
    } else {
      healthBar?.updateHealth(health, maxHealth);
    }
  }

  void gainPowerUp(PowerUpType type) {
    if (powerUpLevels.containsKey(type)) {
      powerUpLevels[type] =
          (powerUpLevels[type]! + 1).clamp(1, 6); // ✅ Max level 6
    } else {
      powerUpLevels[type] = 1; // ✅ Start at Level 1
    }

    // ✅ Keep track of active power-ups (ensures HUD overlay works)
    activePowerUps[type] = powerUpLevels[type]!;

    // Apply new effect
    PowerUp(type, level: powerUpLevels[type]!).applyEffect(this);

    // Show the updated buffs on screen
    gameRef.overlays.add('powerUpBuffs');
  }

  void gainHealth(int amount) {
    if (health < maxHealth && amount > 0) {
      // ✅ Only heal if not at max HP
      int healedAmount = ((health + amount) > maxHealth)
          ? (maxHealth - health)
          : amount; // ✅ Cap healing at max HP

      health += healedAmount;

      // ✅ Only spawn "+HP" text if healing actually happened
      if (healedAmount > 0) {
        final healingNumber = HealingNumber(healedAmount, position.clone());
        gameRef.add(healingNumber);
      }
    }
  }
}
