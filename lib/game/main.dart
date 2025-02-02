import 'dart:async'; // Ensure this is imported
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'experience.dart';
import 'customcamera.dart';
import 'hud.dart';
import 'player.dart';
import 'powerup.dart';
import 'enemy.dart';
import 'wave1Enemy.dart';
import 'wave2Enemy.dart';
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
      _selectingAbilities = true;
    });
  }

  void onAbilitiesSelected(List<String> abilities) {
    setState(() {
      selectedAbilities = abilities;
      _gameStarted = true;
      _selectingAbilities = false;
    });
  }

  void openOptions() {
    print("⚙ Options menu clicked!");
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
              ),
            if (_selectingAbilities)
              AbilitySelectionScreen(
                onAbilitiesSelected: onAbilitiesSelected,
              ),
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
  late final AudioPlayer _bgmPlayer;
  late ValueNotifier<int> gameHudNotifier;
  int enemyCount = 0;
  int maxEnemies = 30;
  List<PowerUpType> powerUpOptions = [];
  final List<String> selectedAbilities;

  bool isPaused = false;
  int remainingTime = 1200; // 20 minutes in seconds

  RogueShooterGame({required this.selectedAbilities});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('music/soft_etheral.mp3'));
    await _bgmPlayer.setVolume(.2);
    gameHudNotifier = ValueNotifier<int>(remainingTime);

    customCamera = CustomCamera(
      screenSize: size, // Ensure screen size is passed
      worldSize: Vector2(1280, 1280), // Set the world size
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

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ Ensure the camera follows the player
    customCamera.follow(player.position, dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // ✅ Apply custom camera transformation
    customCamera.applyTransform(canvas);

    super.render(canvas);

    canvas.restore();
  }

  void _applyAbilitiesToPlayer() {
    for (String abilityName in selectedAbilities) {
      Ability? ability = AbilityFactory.createAbility(abilityName);
      if (ability != null) {
        player.addAbility(ability);
      }
    }
  }

  void startGameTimer() {
    gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        if (remainingTime > 0) {
          remainingTime--;
          gameHudNotifier.value = remainingTime;
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
        spawnEnemyWave(10);
      },
    );
    add(enemySpawnerTimer);

    TimerComponent debugWaveSpawner = TimerComponent(
      period: 5.0, // ✅ Adjusted to 5 seconds
      repeat: true,
      onTick: () {
        spawnEnemyWave(50);
      },
    );
    add(debugWaveSpawner);
  }

  void spawnEnemyWave(int count) {
    for (int i = 0; i < count; i++) {
      final spawnPosition = _getRandomSpawnPosition();

      BaseEnemy enemy = (i % 2 == 0)
          ? Wave1Enemy(
              player: player,
              speed: 100,
              health: 100,
              size: Vector2(32, 32),
            )
          : Wave2Enemy(
              player: player,
              speed: 120,
              health: 80,
              size: Vector2(32, 32),
            );

      enemy.position = spawnPosition;
      enemy.onRemoveCallback = () {
        enemyCount--;
      };

      enemyCount++;
      add(enemy);
    }

    print("🔥 Spawned $count enemies!");
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}"; // Ensures two-digit seconds
  }

  void triggerEvent() {
    print("🔹 EVENT TRIGGERED at ${formatTime(remainingTime)}");

    if (remainingTime == 1140) {
      spawnEnemyWave(20);
      print("⚔ 19:00 - Spawned 20 enemies!");
    } else if (remainingTime == 1080) {
      maxEnemies += 5;
      spawnEnemyWave(20);
      print("🔥 18:00 - Increased max enemies to $maxEnemies!");
    } else if (remainingTime == 600) {
      maxEnemies += 10;
      spawnEnemyWave(20);
      print("💀 10:00 - Further increased max enemies!");
    } else if (remainingTime == 300) {
      maxEnemies += 15;
      spawnEnemyWave(20);
      print("⚡ 5:00 - Max enemies: $maxEnemies");
    } else if (remainingTime == 60) {
      spawnEnemyWave(30);
      print("🚨 1:00 - Final chaos wave!");
    }
  }

  void endGame() {
    overlays.add('gameOver');
    pauseEngine();
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
            spawnEnemyWave(10);
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
}
