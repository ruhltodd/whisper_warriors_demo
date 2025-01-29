import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'healthbar.dart';
import 'main.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'whisperwarrior.dart';

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
  Vector2 joystickDelta = Vector2.zero(); // Joystick movement delta
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

    // Initialize the WhisperWarrior sprite for animations
    whisperWarrior = WhisperWarrior()
      ..size = size.clone()
      ..anchor = Anchor.center
      ..position = position.clone(); // Sync initial position
    gameRef.add(whisperWarrior); //
  }

  void updateJoystick(Vector2 delta) {
    joystickDelta = delta;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Optionally render a debugging rectangle for the Player
    //final paint = Paint()..color = const Color(0xFF0000FF); // Blue color
    // final rect = Rect.fromLTWH(0, 0, size.x, size.y); // Player size
    //canvas.drawRect(rect, paint);
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
    if (joystickDelta.length > 0) {
      position += joystickDelta.normalized() * speed * dt;
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
    if (healthBar != null) {
// Center the health bar above the player's sprite
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }
  }

  void shootProjectile() {
    whisperWarrior.playAnimation('idle'); // Play attack animation

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
