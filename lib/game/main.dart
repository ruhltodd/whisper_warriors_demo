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
import 'enemy2.dart';

void main() {
  runApp(GameWidget(
    game: RogueShooterGame(),
    overlayBuilderMap: {
      'hud': (_, game) => HUD(
            onJoystickMove: (delta) =>
                (game as RogueShooterGame).player.updateJoystick(delta),
            experienceBar: (game as RogueShooterGame).experienceBar,
            game: game as RogueShooterGame,
          ),
      'powerUpSelection': (_, game) => PowerUpSelectionOverlay(
            game: game as RogueShooterGame,
          ),
      'powerUpBuffs': (_, game) => PowerUpBuffsOverlay(
            game: game as RogueShooterGame,
          ),
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
  late TimerComponent enemy2SpawnerTimer;
  int enemyCount = 0;
  int maxEnemies = 5;
  List<PowerUpType> powerUpOptions = [];
  late ValueNotifier<int> gameHudNotifier;
  bool isPaused = false;
  int remainingTime = 1200; // 20 minutes in seconds
  bool enemy2Spawned = false; // ✅ Track if Enemy2 has been spawned

  @override
  Future<void> onLoad() async {
    super.onLoad();
    gameHudNotifier = ValueNotifier<int>(remainingTime);

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
    print("🔹 EVENT TRIGGERED at ${formatTime(remainingTime)}");

    if (remainingTime == 1140 && !enemy2Spawned) {
      print("✅ 19:00 HIT! Spawning Enemy2...");
      spawnEnemy2Wave();
      enemy2Spawned = true;
    } else if (remainingTime == 1080) {
      maxEnemies += 5;
      print("⚔ Increased max enemies to $maxEnemies!");
    } else if (remainingTime == 600) {
      maxEnemies += 10;
      print("🔥 Further increased max enemies to $maxEnemies!");
    } else if (remainingTime == 300) {
      maxEnemies += 15;
      print("💀 Final difficulty increase! Max enemies: $maxEnemies");
    } else if (remainingTime == 60) {
      print("🕛 FINAL MINUTE! Prepare for chaos!");
    }
  }

  void endGame() {
    overlays.add('gameOver');
    pauseEngine();
  }

  void startGameTimer() {
    gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        if (remainingTime > 0) {
          print("🕒 Timer Tick! Remaining Time: $remainingTime"); // ✅ Debugging

          remainingTime--;
          gameHudNotifier.value = remainingTime;

          // ✅ Call `triggerEvent()` every second to check conditions
          triggerEvent();
        }

        if (remainingTime <= 0) {
          endGame();
        }
      },
    );
    add(gameTimer);
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

  void spawnEnemy2Wave() {
    print("🆕 Spawning initial wave of Enemy2");

    for (int i = 0; i < 3; i++) {
      addEnemy2();
    }

    enemy2SpawnerTimer = TimerComponent(
      period: 20.0,
      repeat: true,
      onTick: () {
        print("🆕 Enemy2 Spawned");
        addEnemy2();
      },
    );

    add(enemy2SpawnerTimer);
  }

  void addEnemy2() {
    final spawnPosition = _getRandomSpawnPosition();
    final enemy2 = Enemy2(player)..position = spawnPosition;

    enemyCount++;
    add(enemy2);
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
