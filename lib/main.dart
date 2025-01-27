import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';

void main() {
  runApp(GameWidget(game: RogueShooterGame()));
}

class RogueShooterGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  late Player player;
  late ExperienceBar experienceBar;
  late JoystickComponent joystick; // Joystick addition
  int wave = 1; // Track the current wave
  int enemiesToSpawn = 5; // Number of enemies to spawn per wave

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add the player
    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..size = Vector2(50, 50)
      ..anchor = Anchor.center;

    add(player);

    // Add the joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
          radius: 15, paint: Paint()..color = const Color(0xFFCCCCCC)),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = const Color(0xFF888888)),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );

    player.joystick = joystick; // Pass the joystick to the player
    add(joystick);

    // Add the experience bar
    experienceBar = ExperienceBar();
    add(experienceBar);

    // Start the wave system
    startWave();
  }

  void startWave() async {
    for (int i = 0; i < enemiesToSpawn; i++) {
      spawnEnemy();
      await Future.delayed(const Duration(seconds: 1)); // Delay between spawns
    }

    // Wait before starting the next wave
    await Future.delayed(const Duration(seconds: 5));
    wave++;
    enemiesToSpawn += 2; // Increase difficulty by adding more enemies
    startWave();
  }

  void spawnEnemy() {
    final randomPosition = Vector2.random();
    randomPosition.multiply(Vector2(size.x, size.y));

    final enemy = Enemy(player)
      ..position = randomPosition
      ..size = Vector2(40, 40)
      ..anchor = Anchor.center;

    add(enemy);
  }
}

class Player extends RectangleComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final double speed = 200; // Movement speed
  final double firingCooldown = 0.5; // Cooldown period in seconds
  double timeSinceLastShot = 0.0; // Time since the last shot
  int health = 10; // Player's starting health
  int maxHealth = 10; // Player's maximum health
  int level = 1;
  int exp = 0;
  int expToNextLevel = 100; // Starting experience threshold
  HealthBar? healthBar; // Health bar component
  JoystickComponent? joystick; // Reference to the joystick

  Player() : super(paint: Paint()..color = const Color(0xFF00FF00)) {
    add(RectangleHitbox()); // Add a hitbox for collision
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add the health bar above the player
    healthBar = HealthBar(this);
    gameRef.add(healthBar!);
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
    if (health <= 0) {
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
    }

    // Shoot a projectile if cooldown allows
    if (timeSinceLastShot >= firingCooldown) {
      shootProjectile();
      timeSinceLastShot = 0.0; // Reset the timer after firing
    }
  }

  void shootProjectile() {
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

class HealthBar extends PositionComponent {
  final Player player;
  final double barWidth = 50; // Fixed width of the health bar
  final double barHeight = 5; // Fixed height of the health bar
  late Paint greenPaint;
  late Paint redPaint;

  HealthBar(this.player) {
    greenPaint = Paint()..color = const Color(0xFF00FF00); // Green for health
    redPaint = Paint()
      ..color = const Color(0xFFFF0000); // Red for missing health
    size = Vector2(barWidth, barHeight);
  }

  void updateHealth(int currentHealth, int maxHealth) {
    // Ensure that the health value scales dynamically within the bar's size
    double healthPercentage = currentHealth / maxHealth;
    greenPaint.color = currentHealth <= maxHealth * 0.25
        ? const Color(0xFFFF0000) // Turn red if health is low
        : const Color(0xFF00FF00); // Green otherwise

    // Update the width of the health bar to reflect the current health percentage
    size = Vector2(barWidth * healthPercentage, barHeight);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the red background bar (always full width)
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), redPaint);

    // Draw the green health bar proportional to the current health
    canvas.drawRect(size.toRect(), greenPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Position the health bar above the player
    position = player.position - Vector2(barWidth / 2, player.size.y / 2 + 10);
  }
}

class Projectile extends CircleComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;

  Projectile({required this.damage})
      : super(paint: Paint()..color = const Color(0xFFFFFF00)) {
    add(CircleHitbox()); // Add a hitbox for collision
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the projectile
    position += velocity * dt;

    // Remove projectile if it goes off-screen
    if (position.y < 0 ||
        position.y > gameRef.size.y ||
        position.x < 0 ||
        position.x > gameRef.size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      other.takeDamage(damage); // Deal damage to the enemy
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}

class Enemy extends RectangleComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final double speed = 100;
  int health = 3;

  Enemy(this.player) : super(paint: Paint()..color = const Color(0xFFFF0000)) {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move toward the player
    final direction = (player.position - position).normalized();
    position += direction * speed * dt;

    // Damage the player if too close
    if ((player.position - position).length < 10) {
      player.takeDamage(1); // Deal 1 damage to the player
      removeFromParent(); // Remove the enemy after dealing damage
    }
  }

  void takeDamage(int damage) {
    health -= damage;

    // Spawn damage number
    final damageNumber = DamageNumber(damage, position.clone());
    gameRef.add(damageNumber);

    if (health <= 0) {
      // Drop an experience item
      final drop = DropItem(expValue: 10)..position = position.clone();
      gameRef.add(drop);

      removeFromParent(); // Remove enemy when health is depleted
    }
  }
}

class DamageNumber extends TextComponent with HasGameRef<RogueShooterGame> {
  final Vector2 initialPosition;
  final int damage;
  double timer = 1.0; // Display time in seconds

  DamageNumber(this.damage, this.initialPosition)
      : super(
          text: '-$damage',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ) {
    position = initialPosition;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center; // Ensure the text is centered at its position
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the damage number upward and reduce its opacity over time
    position += Vector2(0, -20 * dt); // Move upward
    timer -= dt;
    if (timer <= 0) {
      removeFromParent(); // Remove after time expires
    }
  }
}

class DropItem extends CircleComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final int expValue;
  DropItem({required this.expValue}) {
    paint = Paint()..color = const Color(0xFFFFD700); // Gold for coin
    size = Vector2(15, 15);
    add(CircleHitbox()); // Add a hitbox for collision
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.gainExperience(expValue); // Player gains experience
      removeFromParent(); // Remove the drop after collection
    }
    super.onCollision(intersectionPoints, other);
  }
}

class ExperienceBar extends PositionComponent
    with HasGameRef<RogueShooterGame> {
  final double barWidth = 200; // Width of the experience bar
  final double barHeight = 10; // Height of the experience bar
  double currentExp = 0;
  double expToLevel = 100;
  int playerLevel = 1;

  ExperienceBar() {
    width = barWidth;
    height = barHeight;
  }

  void updateExperience(int exp, int expToNextLevel, int level) {
    currentExp = exp.toDouble();
    expToLevel = expToNextLevel.toDouble();
    playerLevel = level;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the full bar background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, barWidth, barHeight),
      Paint()..color = const Color(0xFF444444),
    );

    // Draw the filled portion
    final filledWidth = (currentExp / expToLevel) * barWidth;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, filledWidth, barHeight),
      Paint()..color = const Color(0xFF00FF00), // Green for experience
    );

    // Draw the player level text
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.render(canvas, 'Level: $playerLevel', Vector2(5, -20));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Position the experience bar at the top-left corner of the screen
    position = Vector2(10, 50); // A fixed position with padding
  }
}
