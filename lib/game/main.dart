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
import 'enemy.dart';
import 'wave1Enemy.dart';
import 'wave2Enemy.dart';
import 'mainmenu.dart';
import 'abilityselectionscreen.dart';
import 'abilityfactory.dart';
import 'abilities.dart';
import 'boss1.dart';
import 'package:flame/effects.dart';
import 'explosion.dart';

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
  late SpiritBar experienceBar;
  late SpriteComponent grassMap;
  late TimerComponent enemySpawnerTimer;
  late TimerComponent gameTimer;
  late final AudioPlayer _bgmPlayer;
  late ValueNotifier<int> gameHudNotifier;
  int enemyCount = 0;
  int maxEnemies = 30;
  final List<String> selectedAbilities;
  final Random random = Random(); // ✅ Define Random instance

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

    experienceBar = SpiritBar();
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
      period: 5.0,
      repeat: true,
      onTick: () {
        checkLevelUpScaling();
        spawnEnemyWave(10);
      },
    );
    add(enemySpawnerTimer);
  }

  void spawnEnemyWave(int count) {
    for (int i = 0; i < count; i++) {
      final spawnPosition = _getRandomSpawnPosition();

      BaseEnemy enemy;
      if (remainingTime <= 1140) {
        // ✅ After 60 seconds, allow Wave2Enemy to spawn
        enemy = (i % 2 == 0)
            ? Wave1Enemy(
                player: player,
                speed: 70,
                health: 100,
                size: Vector2(64, 64),
              )
            : Wave2Enemy(
                player: player,
                speed: 50,
                health: 400,
                size: Vector2(128, 128),
              );
      } else {
        // ✅ Before 60 seconds, only spawn Wave1Enemy
        enemy = Wave1Enemy(
          player: player,
          speed: 100,
          health: 100,
          size: Vector2(64, 64),
        );
      }

      enemy.position = spawnPosition;
      enemy.onRemoveCallback = () {
        enemyCount--;
      };

      enemyCount++;
      add(enemy);
    }

    print("🔥 Spawned $count enemies!");
  }

  void _shakeScreen(CustomCamera camera) {
    print("🌪 SCREEN SHAKE!");

    Vector2 originalPosition = camera.position.clone();

    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        camera.position += Vector2(
            5 - random.nextDouble() * 10, // Random horizontal shake
            5 - random.nextDouble() * 10 // Random vertical shake
            );
      });
    }

    Future.delayed(Duration(milliseconds: 300), () {
      camera.position = originalPosition; // ✅ Reset position after shake
    });
  }

  void _spawnBoss() {
    print("💀 BOSS ARRIVING!");

    final enemies = children.whereType<BaseEnemy>().toList();
    for (var enemy in enemies) {
      enemy.removeFromParent();
    }

    remove(enemySpawnerTimer);

    final boss = Boss1(
      player: player,
      speed: 20,
      health: 5000,
      size: Vector2(128, 128),
    )
      ..position = Vector2(size.x / 2, -300)
      ..anchor = Anchor.center;
    add(boss);

    Future.delayed(Duration(milliseconds: 1500), () {
      boss.position = Vector2(size.x / 2, size.y / 3); // ✅ Boss lands
      _shakeScreen(customCamera); // ✅ Trigger screen shake
      _triggerBossImpactEffect(boss.position);
    });

    print("🔥 BOSS HAS ENTERED THE ARENA!");
  }

  void _triggerBossImpactEffect(Vector2 position) {
    print("💥 Boss slammed into the ground!");
    add(Explosion(position)); // ✅ Explosion at impact location
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}"; // Ensures two-digit seconds
  }

  void triggerEvent() {
    print("🔹 EVENT TRIGGERED at ${formatTime(remainingTime)}");

    if (remainingTime == 1180) {
      spawnEnemyWave(20);
      print("⚔ 19:00 - Spawned 20 enemies!");
    } else if (remainingTime == 1140) {
      // ✅ Change to your boss spawn time
      print("💀 Boss is arriving, removing all enemies!");

      // ✅ Stop all enemy spawners
      remove(enemySpawnerTimer);

      // ✅ Remove all existing enemies
      for (var enemy in children.whereType<BaseEnemy>()) {
        enemy.removeFromParent();
      }

      _spawnBoss();
    }
  }

  void endGame() {
    overlays.add('gameOver');
    pauseEngine();
  }

  void checkLevelUpScaling() {
    if (player.spiritLevel >= 3 && maxEnemies != 20) {
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
