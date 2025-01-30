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
import 'powerup.dart';

void main() {
  runApp(GameWidget(
    game: RogueShooterGame(),
    overlayBuilderMap: {
      'hud': (_, game) => HUD(
            onJoystickMove: (delta) =>
                (game as RogueShooterGame).player.updateJoystick(delta),
            experienceBar: (game as RogueShooterGame).experienceBar,
            game: game as RogueShooterGame, // ✅ Fix: Pass the game reference
          ),
      'powerUpSelection': (_, game) => PowerUpSelectionOverlay(
            game: game as RogueShooterGame,
          ),
      'powerUpBuffs': (_, game) => PowerUpBuffsOverlay(
            game: game as RogueShooterGame,
          ), // ✅ NEW Buff UI
    },
  ));
}

class RogueShooterGame extends FlameGame with HasCollisionDetection {
  late CustomCamera customCamera;
  late Player player;
  late ExperienceBar experienceBar;
  late SpriteComponent grassMap;
  late TimerComponent enemySpawnerTimer;
  late TimerComponent gameTimer;
  int enemyCount = 0;
  int maxEnemies = 5;
  List<PowerUpType> powerUpOptions = [];
  ValueNotifier<int> gameHudNotifier = ValueNotifier<int>(1200); // 20 min timer
  bool isPaused = false;
  int remainingTime = 1200; // 20 minutes in seconds

  @override
  Future<void> onLoad() async {
    super.onLoad();

    startGameTimer();

    customCamera = CustomCamera(
      screenSize: size,
      worldSize: Vector2(1280, 1280),
    );

    grassMap = SpriteComponent(
      sprite: await loadSprite('grass_map.png'),
      size: Vector2(1280, 1280),
      position: Vector2.zero(),
    );
    add(grassMap);

    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..size = Vector2(64, 64);
    add(player);

    experienceBar = ExperienceBar();
    customCamera.follow(player.position, 0);
    overlays.add('hud');

    startEnemySpawner();
    startGameTimer();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  void triggerEvent() {
    if (remainingTime == 1080) {
      maxEnemies += 5;
    } else if (remainingTime == 600) {
      maxEnemies += 10;
    } else if (remainingTime == 300) {
      maxEnemies += 15;
    } else if (remainingTime == 60) {
      print("Final minute!");
    }
  }

  void endGame() {
    overlays.add('gameOver');
    pauseEngine();
  }

  void startGameTimer() {
    gameTimer = TimerComponent(
      period: 1.0, // ⏳ Tick every second
      repeat: true,
      onTick: () {
        if (remainingTime > 0) {
          remainingTime--; // ✅ Decrease timer
        }

        if (remainingTime % 120 == 0) {
          triggerEvent(); // ✅ Trigger game events every 2 minutes
        }

        if (remainingTime <= 0) {
          endGame(); // ✅ End the game when timer reaches 0
        }
      },
    );

    add(gameTimer); // ✅ Ensure TimerComponent is added to the game
  }

  void startEnemySpawner() {
    enemySpawnerTimer = TimerComponent(
      period: 2.0,
      repeat: true,
      onTick: () {
        checkLevelUpScaling();
        if (enemyCount < maxEnemies) {
          addEnemy();
        }
      },
    );
    add(enemySpawnerTimer);
  }

  void addEnemy() {
    final spawnPosition = _getRandomSpawnPosition();
    final enemy = Enemy(player)
      ..position = spawnPosition
      ..onRemoveCallback = () {
        enemyCount--;
      };
    enemyCount++;
    add(enemy);
  }

  void showPowerUpSelection() {
    pauseGame();
    List<PowerUpType> allPowerUps = PowerUpType.values.toList();
    allPowerUps.shuffle();
    powerUpOptions = allPowerUps.take(3).toList();
    overlays.add('powerUpSelection');
  }

  void selectPowerUp(PowerUpType selectedType) {
    player.gainPowerUp(selectedType);
    overlays.remove('powerUpSelection');
    resumeGame();
  }

  void pauseGame() {
    isPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine();
  }

  void checkLevelUpScaling() {
    if (player.level >= 3 && maxEnemies != 20) {
      maxEnemies = 20;
      remove(enemySpawnerTimer);
      enemySpawnerTimer = TimerComponent(
        period: 1.0,
        repeat: true,
        onTick: () {
          if (enemyCount < maxEnemies) {
            addEnemy();
          }
        },
      );
      add(enemySpawnerTimer);
    }
  }

  Vector2 _getRandomSpawnPosition() {
    final random = Random();
    final spawnMargin = 50.0;
    Vector2 spawnPosition;

    do {
      final side = random.nextInt(4);
      switch (side) {
        case 0:
          spawnPosition = Vector2(random.nextDouble() * size.x, -spawnMargin);
          break;
        case 1:
          spawnPosition =
              Vector2(size.x + spawnMargin, random.nextDouble() * size.y);
          break;
        case 2:
          spawnPosition =
              Vector2(random.nextDouble() * size.x, size.y + spawnMargin);
          break;
        case 3:
          spawnPosition = Vector2(-spawnMargin, random.nextDouble() * size.y);
          break;
        default:
          spawnPosition = Vector2.zero();
      }
    } while ((spawnPosition - player.position).length < 100.0);

    return spawnPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);
    customCamera.follow(player.position, dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    customCamera.applyTransform(canvas);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void onRemove() {
    super.onRemove();
    enemySpawnerTimer.timer.stop();
  }
}
