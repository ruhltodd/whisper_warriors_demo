import 'dart:async'; // Ensure this is imported
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
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
import 'mainmenu.dart';
import 'abilityselectionscreen.dart';
import 'abilityfactory.dart';
import 'abilities.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _gameStarted = false;
  bool _selectingAbilities = false;
  List<String> selectedAbilities = [];

  void startGame() {
    setState(() {
      _selectingAbilities = true; // ✅ Move to ability selection first
    });
  }

  void onAbilitiesSelected(List<String> abilities) {
    setState(() {
      selectedAbilities = abilities;
      _gameStarted = true;
      _selectingAbilities = false; // ✅ Move to actual game
      print(
          "✅ Abilities received in MyApp: $selectedAbilities"); // 🔍 Debugging
    });
  }

  void openOptions() {
    print("⚙ Options menu clicked!"); // ✅ Placeholder for options menu
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            if (!_gameStarted && !_selectingAbilities)
              MainMenu(
                startGame: startGame,
                openOptions: openOptions,
              ), // ✅ Show Main Menu first

            if (_selectingAbilities)
              AbilitySelectionScreen(
                onAbilitiesSelected: onAbilitiesSelected,
              ), // ✅ Show Ability Selection next

            if (_gameStarted)
              GameWidget(
                game: RogueShooterGame(selectedAbilities: selectedAbilities),
                overlayBuilderMap: {
                  'hud': (_, game) => HUD(
                        onJoystickMove: (delta) => (game as RogueShooterGame)
                            .player
                            .updateJoystick(delta),
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
              ),
          ],
        ),
      ),
    );
  }
}

class RogueShooterGame extends FlameGame with HasCollisionDetection {
  late CustomCamera customCamera;
  late Player player;
  late ExperienceBar experienceBar;
  late SpriteComponent grassMap;
  late TimerComponent enemySpawnerTimer;
  late TimerComponent gameTimer;
  late TimerComponent enemy2SpawnerTimer;
  late final AudioPlayer _bgmPlayer;
  late ValueNotifier<int> gameHudNotifier;
  int enemyCount = 0;
  int maxEnemies = 30;
  List<PowerUpType> powerUpOptions = [];
  final List<String> selectedAbilities;

  bool isPaused = false;
  int remainingTime = 1200; // 20 minutes in seconds
  bool enemy2Spawned = false; // ✅ Track if Enemy2 has been spawned

  RogueShooterGame({required this.selectedAbilities});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _bgmPlayer = AudioPlayer();

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // ✅ Loop the music
    await _bgmPlayer.play(AssetSource('music/soft_etheral.mp3'));
    await _bgmPlayer.setVolume(.2);
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

    _applyAbilitiesToPlayer();

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

  void spawnDebugWave() {
    spawnEnemyWave(20); // ✅ Spawn 20 enemies instantly
  }

  void _applyAbilitiesToPlayer() {
    for (String abilityName in selectedAbilities) {
      Ability? ability = AbilityFactory.createAbility(abilityName);
      if (ability != null) {
        player.addAbility(ability);
        print("🔥 Ability Added: ${ability.name}"); // 🔍 Debugging
      } else {
        print("❌ ERROR: Ability not found in factory!"); // 🔍 Debugging
      }
    }
    spawnDebugWave();
  }

  void triggerEvent() {
    print("🔹 EVENT TRIGGERED at ${formatTime(remainingTime)}");

    if (remainingTime == 1140 && !enemy2Spawned) {
      print("✅ 19:00 HIT! Spawning Enemy2...");
      spawnEnemy2Wave();
      enemy2Spawned = true;
    } else if (remainingTime == 1080) {
      maxEnemies += 5;
      spawnEnemyWave(20); // ✅ Spawn 20 enemies
      print("⚔ Increased max enemies to $maxEnemies!");
    } else if (remainingTime == 600) {
      maxEnemies += 10;
      spawnEnemyWave(20); // ✅ Spawn 20 enemies
      print("🔥 Further increased max enemies to $maxEnemies!");
    } else if (remainingTime == 300) {
      maxEnemies += 15;
      spawnEnemyWave(20); // ✅ Spawn 20 enemies
      print("💀 Final difficulty increase! Max enemies: $maxEnemies");
    } else if (remainingTime == 60) {
      spawnEnemyWave(20); // ✅ Keep spawning 20 per wave
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

  void spawnEnemyWave(int count) {
    print("🔥 Spawning $count enemies at once!");

    for (int i = 0; i < count; i++) {
      final spawnPosition = _getRandomSpawnPosition();
      final enemy = Enemy(player)
        ..position = spawnPosition
        ..onRemoveCallback = () {
          enemyCount--;
        };
      enemyCount++;
      add(enemy);
    }
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
    _bgmPlayer.stop(); // ✅ Stop music when leaving menu
  }
}
