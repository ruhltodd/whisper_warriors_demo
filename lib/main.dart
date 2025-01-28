import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
//import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/sprite.dart';

void main() {
  runApp(GameWidget(game: RogueShooterGame()));
}

class RogueShooterGame extends FlameGame with HasCollisionDetection {
  late Player player; // Player now includes WhisperWarrior functionality
  late ExperienceBar experienceBar;
  late JoystickComponent joystick;
  int baseEnemiesToSpawn = 5; // Starting enemies per level
  int enemiesToSpawn = 5; // Updated each level
  double spawnDelay = 1.0; // Delay between enemy spawns
  bool debugMode = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add the grass map as the background
    final grassMap = SpriteComponent(
      sprite: await loadSprite('grass_map.png'),
      size: Vector2(1280, 1280), // Update size based on your map's resolution
      position: Vector2.zero(), // Start at the top-left corner
    );
    add(grassMap);

    // Initialize the player
    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..size = Vector2(64, 64); // Ensure size matches the WhisperWarrior sprite
    await add(player);

    // Add the experience bar
    experienceBar = ExperienceBar();
    add(experienceBar);

    // Add the joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
          radius: 15, paint: Paint()..color = const Color(0xFFCCCCCC)),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = const Color(0xFF888888)),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );

    player.joystick = joystick; // Assign joystick to player
    add(joystick);

    // Start the wave system
    startWave();
  }

  void startWave() async {
    enemiesToSpawn =
        baseEnemiesToSpawn + (player.level - 1) * 2; // Scale with level

    for (int i = 0; i < enemiesToSpawn; i++) {
      spawnEnemy();
      await Future.delayed(Duration(
          milliseconds: (spawnDelay * 1000).toInt())); // Delay between spawns
    }

    // Start the next wave after all enemies have spawned
    await Future.delayed(
        const Duration(seconds: 5)); // Optional delay between waves
    startWave(); // Trigger the next wave
  }

  void spawnEnemy() {
    final Vector2 spawnPosition = _getRandomOffscreenPosition();

    final enemy = Enemy(player)
      ..position = spawnPosition
      ..size = Vector2(40, 40)
      ..anchor = Anchor.center;

    add(enemy);
  }

  Vector2 _getRandomOffscreenPosition() {
    final random = Random();
    final spawnMargin = 50.0; // Distance from screen edges to spawn enemies
    Vector2 position;

    do {
      final side = random.nextInt(
          4); // Randomly choose a side (0 = top, 1 = right, 2 = bottom, 3 = left)
      switch (side) {
        case 0: // Top
          position = Vector2(random.nextDouble() * size.x, -spawnMargin);
          break;
        case 1: // Right
          position =
              Vector2(size.x + spawnMargin, random.nextDouble() * size.y);
          break;
        case 2: // Bottom
          position =
              Vector2(random.nextDouble() * size.x, size.y + spawnMargin);
          break;
        case 3: // Left
          position = Vector2(-spawnMargin, random.nextDouble() * size.y);
          break;
        default:
          position = Vector2.zero();
      }
    } while (_isTooCloseToPlayer(position));

    return position;
  }

  bool _isTooCloseToPlayer(Vector2 position) {
    const safeDistance = 100.0; // Minimum distance from the player
    return (player.position - position).length < safeDistance;
  }
}

class Player extends PositionComponent
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
      //whisperWarrior.playAnimation('walk'); // Play walking animation
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

class Projectile extends SpriteComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Vector2 velocity;
  final int damage;

  Projectile({required this.damage})
      : super(size: Vector2(16, 16)); // Adjust size as needed

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite from assets
    sprite = await gameRef.loadSprite('projectile_normal.png');

    // Add a circular hitbox for collision
    add(CircleHitbox()..debugMode = false); // Disable debug visuals
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
      removeFromParent(); // Destroy projectile after collision
    }
    super.onCollision(intersectionPoints, other);
  }
}

class Enemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final double speed = 100;
  int health = 3;

  Enemy(this.player)
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite sheet
    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('mob1.png'),
      srcSize: Vector2(32, 32),
    );

    // Create a walking animation
    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, to: 2);

    // Add a collision hitbox
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
      removeFromParent();
    }
  }

  void takeDamage(int damage) {
    health -= damage;
    if (health <= 0) {
      print(
          'Enemy position at death: $position'); // Log position before dropping
      _dropItem(); // Ensure the item is dropped before removal
      removeFromParent();
    }
  }

  void _dropItem() {
    final drop = DropItem(expValue: 10)
      ..position = position.clone()
      ..size = Vector2(15, 15);
    gameRef.world.add(drop);
    print('DropItem added at position: ${drop.position}');
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
    add(CircleHitbox.relative(1.5, parentSize: size)); // Adjusted hitbox size
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      print('DropItem collected by Player at position: $position'); // Debug log
      other.gainExperience(expValue); // Grant experience
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

class WhisperWarrior extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Map<String, SpriteAnimation> animations;
  bool isLoaded = false;
  JoystickComponent? joystick; // Joystick reference for movement

  WhisperWarrior()
      : super(
          size: Vector2(64, 64),
          paint: Paint()..blendMode = BlendMode.srcOver,
        );

  @override
  Future<void> onLoad() async {
    print("Loading WhisperWarrior...");

    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_spritesheet.png'),
      srcSize: Vector2(64, 64),
    );

    animations = {
      'idle': spriteSheet.createAnimation(row: 0, stepTime: 0.2),
      //'walk': spriteSheet.createAnimation(row: 1, stepTime: 0.15),
      //  'attack': spriteSheet.createAnimation(row: 2, stepTime: 0.1),
      //  'hit': spriteSheet.createAnimation(row: 3, stepTime: 0.2),
      //  'death': spriteSheet.createAnimation(row: 4, stepTime: 0.25),
    };

    animation = animations['idle'];
    isLoaded = true;

    print("WhisperWarrior loaded successfully!");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle joystick movement
    if (joystick != null && joystick!.delta.length > 0) {
      // Move the WhisperWarrior based on joystick input
      position +=
          joystick!.delta.normalized() * 200 * dt; // Adjust speed as needed

      // Play walk animation when moving
      if (animation != animations['walk']) {
        animation = animations['walk'];
      }
    } else {
      // Play idle animation when not moving
      if (animation != animations['idle']) {
        animation = animations['idle'];
      }
    }
  }

  void playAnimation(String animationName) {
    if (!isLoaded) {
      print("Warning: Attempted to play animation before loading completed.");
      return;
    }

    if (animations.containsKey(animationName)) {
      animation = animations[animationName];
    } else {
      print('Animation "$animationName" not found.');
    }
  }
}
