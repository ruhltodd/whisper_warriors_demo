import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'main.dart';
import 'healthbar.dart';
import 'whisperwarrior.dart';
import 'projectile.dart';
import 'enemy.dart';

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final double speed = 150; // Movement speed
  final double firingCooldown = 0.5; // Cooldown period in seconds
  double timeSinceLastShot = 0.5; // Time since the last shot
  int health = 10; // Player's starting health
  int maxHealth = 10; // Player's maximum health
  int level = 1;
  int exp = 0;
  int expToNextLevel = 100; // Starting experience threshold
  HealthBar? healthBar; // Health bar component
  JoystickComponent? joystick; // Reference to the joystick
  late WhisperWarrior whisperWarrior; // Animation component reference

  Player() : super(size: Vector2(64, 64)) {
    add(RectangleHitbox()); // Add a hitbox for collision
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add the health bar above the player
    healthBar = HealthBar(this);
    gameRef.add(healthBar!);

    // Add the animated player sprite
    whisperWarrior = WhisperWarrior()
      ..position = position.clone()
      ..size = size.clone();
    gameRef.add(whisperWarrior);
  }

  int get damage => 1 + (level - 1) * 1; // Base damage scales with level

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
    expToNextLevel = (expToNextLevel * 1.5).toInt(); // Increase threshold
    maxHealth = (maxHealth * 1.2).toInt(); // Increase max health by 20%
    health = maxHealth; // Restore health to max on level up
    healthBar?.updateHealth(health, maxHealth); // Update the health bar
  }

  void takeDamage(int damage) {
    health -= damage;
    whisperWarrior.playAnimation('hit'); // Play hit animation
    if (health <= 0) {
      whisperWarrior.playAnimation('death'); // Play death animation
      removeFromParent(); // Remove the player when health is depleted
      healthBar?.removeFromParent(); // Remove the health bar
    } else {
      healthBar?.updateHealth(health, maxHealth); // Update the health bar
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update the firing cooldown timer
    timeSinceLastShot += dt;

    // Move the player using joystick input
    if (joystick != null && joystick!.delta.length > 0) {
      position += joystick!.delta.normalized() * speed * dt;
      whisperWarrior.playAnimation('walk'); // Play walking animation
    } else {
      whisperWarrior
          .playAnimation('idle'); // Play idle animation when not moving
    }

    // Update the position of the animated sprite to match the player's
    whisperWarrior.position = position.clone();

    // Shoot a projectile if cooldown allows
    if (timeSinceLastShot >= firingCooldown) {
      shootProjectile();
      timeSinceLastShot = 0.0; // Reset the timer after firing
    }
  }

  void shootProjectile() {
    whisperWarrior.playAnimation('attack'); // Play attack animation

    final enemies = gameRef.children.whereType<Enemy>();
    if (enemies.isEmpty) return;

    Enemy? closestEnemy;
    double closestDistance = double.infinity;

    for (final enemy in enemies) {
      final distance = (enemy.position - position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestEnemy = enemy;
      }
    }

    if (closestEnemy != null) {
      final direction = (closestEnemy.position - position).normalized();

      final projectile = Projectile(damage: damage)
        ..position = position.clone()
        ..size = Vector2(10, 10)
        ..anchor = Anchor.center
        ..velocity = direction * 300;

      gameRef.add(projectile);
    }
  }
}
