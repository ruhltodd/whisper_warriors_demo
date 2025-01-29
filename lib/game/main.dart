import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
//import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/sprite.dart';
import 'player.dart';
import 'experience.dart';
import 'enemy.dart';

void main() {
  runApp(GameWidget(game: RogueShooterGame()));
}

class RogueShooterGame extends FlameGame with HasCollisionDetection {
  //late World world; // A world to hold all game components
  late CameraComponent cameraComponent; // The camera component
  late Player player; // Player now includes WhisperWarrior functionality
  late ExperienceBar experienceBar;
  late JoystickComponent joystick;
  late SpriteComponent grassMap;
  int baseEnemiesToSpawn = 5; // Starting enemies per level
  int enemiesToSpawn = 5; // Updated each level
  double spawnDelay = 1.0; // Delay between enemy spawns
  bool debugMode = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create and add the world
    world = World();
    add(world);

    // Add the grass map as the background
    grassMap = SpriteComponent(
      sprite: await loadSprite('grass_map.png'),
      size: Vector2(1280, 1280), // Update size based on your map's resolution
      position: Vector2.zero(),
      priority: 0, // Start at the top-left corner
    );
    add(grassMap);
    //world.add(grassMap);

    // Initialize the player
    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..size = Vector2(64, 64)
      ..priority = 1; // Ensure size matches the WhisperWarrior sprite
    add(player);

    // Attach the camera and configure the viewfinder
    // cameraComponent = CameraComponent();
    // add(cameraComponent);

// Lock the camera to follow the player
    // cameraComponent.viewfinder.add(
    //   PositionComponent()..add(player),
    // );
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
