import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'healthbar.dart';
import 'main.dart';
import 'enemy.dart';
import 'wave2Enemy.dart';
import 'projectile.dart';
import 'whisperwarrior.dart';
import 'healingnumber.dart';
import 'abilities.dart';
import 'explosion.dart';
import 'experience.dart';

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  // ✅ Base Stats (before Spirit Level modifications)
  double baseHealth = 100.0;
  double baseSpeed = 120.0;
  double baseAttackSpeed = 1.0; // Attacks per second
  double baseDefense = 0.0; // % Damage reduction
  double baseDamage = 10.0;
  double baseCritChance = 5.0; // % Chance
  double baseCritMultiplier = 1.5; // 1.5x damage on crit

  // ✅ Spirit Level System
  double spiritMultiplier = 1.0; // Scales with Spirit Level
  int spiritLevel = 1;
  double spiritExp = 0.0;
  double spiritExpToNextLevel = 1000.0;

  // ✅ Derived Stats (calculated from Spirit Level)
  double get maxHealth => baseHealth * spiritMultiplier;
  double get movementSpeed => baseSpeed * spiritMultiplier;
  double get attackSpeed => baseAttackSpeed * (1 + (spiritMultiplier - 1));
  double get defense => baseDefense * spiritMultiplier;
  double get damage => baseDamage * spiritMultiplier;
  double get critChance => baseCritChance * spiritMultiplier;
  double get critMultiplier =>
      baseCritMultiplier + ((spiritMultiplier - 1) * 0.5);

  // ✅ Current Health (tracks real-time health)
  double currentHealth = 100.0;

  // ✅ UI & Game Elements
  HealthBar? healthBar;
  Vector2 joystickDelta = Vector2.zero();
  late WhisperWarrior whisperWarrior;
  BaseEnemy? closestEnemy;
  List<Ability> abilities = [];
  final ValueNotifier<List<Ability>> abilityNotifier =
      ValueNotifier<List<Ability>>([]);

  // ✅ Special Player Stats
  double vampiricHealing = 0;
  double blackHoleCooldown = 10;
  double firingCooldown = 1.0;
  double timeSinceLastShot = 1.0;
  double lastExplosionTime = 0.0;
  double explosionCooldown = 0.2;

  Player() : super(size: Vector2(128, 128)) {
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

  void updateSpiritMultiplier() {
    // ✅ Each Spirit Level increases all stats by 5%
    spiritMultiplier = 1.0 + (spiritLevel * 0.05);
  }

  void updateJoystick(Vector2 delta) {
    joystickDelta = delta;
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastShot += dt; // ✅ Ensure cooldown timer increases

    updateSpiritMultiplier();
    updateClosestEnemy(); // 🔥 This ensures `closestEnemy` is updated

    if (joystickDelta.length > 0) {
      position += joystickDelta.normalized() * movementSpeed * dt;
      whisperWarrior.scale.x = joystickDelta.x > 0 ? -1 : 1;
      whisperWarrior.playAnimation('attack');
    } else {
      whisperWarrior.playAnimation('idle');
    }

    whisperWarrior.position = position.clone();

    // ✅ Ensure an enemy is targeted before shooting
    if (timeSinceLastShot >= (1 / attackSpeed) && closestEnemy != null) {
      print("🛑 Projectile removed: Max range exceeded");
      shootProjectile();
      timeSinceLastShot = 0.0; // ✅ Reset cooldown
    }

    if (healthBar != null) {
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }

    for (var ability in abilities) {
      ability.onUpdate(this, dt);
    }
  }

  // ✅ Gain Spirit Experience & Level Up
  void gainSpiritExp(double amount) {
    // ✅ Ensure parameter is double
    spiritExp += amount;

    if (spiritExp >= spiritExpToNextLevel) {
      spiritLevelUp();
    }

    gameRef.experienceBar
        .updateSpirit(spiritExp, spiritExpToNextLevel, spiritLevel);
  }

  void spiritLevelUp() {
    spiritLevel++;
    spiritExp -= spiritExpToNextLevel;
    spiritExpToNextLevel *= 1.2;
    updateSpiritMultiplier();
    print("✨ Spirit Level Up! New Spirit Level: $spiritLevel");
  }

  // ✅ Take Damage & Reduce Spirit Level
  void takeDamage(int damage) {
    double reducedDamage = damage * (1 - (defense / 100));
    currentHealth -=
        reducedDamage.clamp(1, maxHealth).toInt(); // ✅ Explicit cast

    // ✅ Lose Spirit EXP instead of instantly dropping a level
    double expLoss =
        spiritExpToNextLevel * 0.05; // Lose 10% of current level EXP
    spiritExp -= expLoss;

    if (spiritExp < 0) {
      spiritExp = 0; // Prevent negative EXP
    }

    gameRef.experienceBar
        .updateSpirit(spiritExp, spiritExpToNextLevel, spiritLevel);

    whisperWarrior.playAnimation('hit');

    if (currentHealth <= 0) {
      whisperWarrior.playAnimation('death');
      removeFromParent();
      healthBar?.removeFromParent();
    } else {
      healthBar?.updateHealth(
          currentHealth.toInt(), maxHealth.toInt()); // ✅ Explicit cast
    }
  }

  void shootProjectile() {
    if (closestEnemy == null) {
      print("⚠️ No enemy targeted - projectile not fired!");
      return;
    }

    print("🚀 shootProjectile() called!");

    final direction = (closestEnemy!.position - position).normalized();

    final projectile = Projectile(
      damage: damage.toInt(), // ✅ Ensure `damage` is an int
      velocity: direction * 500, // ✅ Now correctly passing velocity
      maxRange: 1600, // ✅ Player projectiles should have a range
    )
      ..position = position.clone()
      ..size = Vector2(50, 50)
      ..anchor = Anchor.center;

    gameRef.add(projectile);
    print("🚀 PLAYER PROJECTILE FIRED!");
  }

  void addAbility(Ability ability) {
    abilities.add(ability);
    abilityNotifier.value = List.from(abilities);
    ability.applyEffect(this);
  }

  bool hasAbility<T extends Ability>() {
    return abilities.any((ability) => ability is T);
  }

  void updateClosestEnemy() {
    final enemies = gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) {
      closestEnemy = null;
      print("No enemies found.");
      return;
    }

    BaseEnemy? newClosest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
      final distance = (enemy.position - position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        newClosest = enemy;
      }
    }

    if (newClosest != closestEnemy) {
      closestEnemy = newClosest;
      print("🎯 New closest enemy assigned at ${closestEnemy?.position}");
    }
  }

  void gainHealth(int amount) {
    if (currentHealth < maxHealth && amount > 0) {
      int healedAmount = ((currentHealth + amount) > maxHealth)
          ? (maxHealth - currentHealth).toInt()
          : amount; // ✅ Explicit cast
      currentHealth += healedAmount;

      if (healedAmount > 0) {
        final healingNumber = HealingNumber(healedAmount, position.clone());
        gameRef.add(healingNumber);
      }
    }
  }

  void triggerExplosion(Vector2 position) {
    double currentTime = gameRef.currentTime();

    // ✅ Prevent excessive explosions
    if (currentTime - lastExplosionTime < explosionCooldown) {
      return;
    }

    lastExplosionTime = currentTime; // ✅ Update cooldown

    gameRef.add(Explosion(position));
    print("💥 Explosion triggered at $position");

    // ✅ Calculate explosion damage based on Spirit Level
    double explosionDamage = damage * 0.25; // Base: 25% of player damage
    explosionDamage *= spiritMultiplier; // Scale with Spirit Level

    // ✅ Apply damage to nearby enemies
    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;

      if (distance < 100.0) {
        // ✅ Explosion radius
        int finalDamage = explosionDamage.toInt().clamp(1, 9999);
        enemy.takeDamage(finalDamage);
        print("🔥 Explosion hit enemy for $finalDamage damage!");
      }
    }
  }

  @override
  void onRemove() {
    abilityNotifier.dispose();
    super.onRemove();
  }
}
