import 'dart:async'; // Ensure this is imported
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'experience.dart';
import 'enemy.dart';
import 'customcamera.dart';
import 'hud.dart';
import 'player.dart';

void main() {
  runApp(GameWidget(
    game: RogueShooterGame(),
    overlayBuilderMap: {
      'hud': (_, game) => HUD(
            onJoystickMove: (delta) =>
                (game as RogueShooterGame).player.updateJoystick(delta),
            experienceBar: (game as RogueShooterGame).experienceBar,
          ),
    },
  ));
}

class RogueShooterGame extends FlameGame with HasCollisionDetection {
  late CustomCamera customCamera;
  late Player player;
  late ExperienceBar experienceBar;
  late SpriteComponent grassMap;
  late TimerComponent enemySpawnerTimer; // Use TimerComponent from Flame
  int enemyCount = 0;
  int maxEnemies = 5;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize the custom camera
    customCamera = CustomCamera(
      screenSize: size,
      worldSize: Vector2(1280, 1280),
    );

    // Add the grass map
    grassMap = SpriteComponent(
      sprite: await loadSprite('grass_map.png'),
      size: Vector2(1280, 1280),
      position: Vector2.zero(),
    );
    add(grassMap);

    // Add the player
    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2) // Center player
      ..size = Vector2(64, 64); // Default size for the player
    add(player);

    // Initialize the experience bar
    experienceBar = ExperienceBar();

    // Center the camera on the player initially
    customCamera.follow(player.position, 0);

    // Add the HUD overlay after all components are initialized
    overlays.add('hud');

    // Start the enemy spawner
    startEnemySpawner();
  }

  void startEnemySpawner() {
    enemySpawnerTimer = TimerComponent(
      period: 2.0, // Spawn enemies every 2 seconds
      repeat: true,
      onTick: () {
        if (enemyCount < maxEnemies) {
          addEnemy();
        }
      },
    );
    add(enemySpawnerTimer); // Add the TimerComponent to the game
  }

  void addEnemy() {
    final spawnPosition = _getRandomSpawnPosition();
    final enemy = Enemy(player)
      ..position = spawnPosition
      ..onRemoveCallback = () {
        enemyCount--; // Decrement enemy count when removed
      };

    // Increment enemy count
    enemyCount++;

    add(enemy);
  }

  Vector2 _getRandomSpawnPosition() {
    final random = Random();
    final spawnMargin = 50.0;
    Vector2 spawnPosition;

    do {
      final side = random.nextInt(4); // Random side (top, right, bottom, left)
      switch (side) {
        case 0:
          spawnPosition =
              Vector2(random.nextDouble() * size.x, -spawnMargin); // Top
          break;
        case 1:
          spawnPosition = Vector2(
              size.x + spawnMargin, random.nextDouble() * size.y); // Right
          break;
        case 2:
          spawnPosition = Vector2(
              random.nextDouble() * size.x, size.y + spawnMargin); // Bottom
          break;
        case 3:
          spawnPosition =
              Vector2(-spawnMargin, random.nextDouble() * size.y); // Left
          break;
        default:
          spawnPosition = Vector2.zero();
      }
    } while ((spawnPosition - player.position).length <
        100.0); // Avoid spawning near the player

    return spawnPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update the custom camera to follow the player
    customCamera.follow(player.position, dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Apply camera transformations
    customCamera.applyTransform(canvas);

    // Render game world
    super.render(canvas);

    canvas.restore();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Stop the timer when the game is removed
    enemySpawnerTimer.timer.stop();
  }
}
