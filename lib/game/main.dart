import 'dart:async'; //
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/itemselectionscreen.dart'; // ✅ Add this
// Ensure this is imported
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:whisper_warriors/game/ui/experience.dart';
import 'package:whisper_warriors/game/ui/notifications.dart';
import 'package:whisper_warriors/game/utils/customcamera.dart';
import 'package:whisper_warriors/game/ui/hud.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/ai/wave1Enemy.dart';
import 'package:whisper_warriors/game/ai/wave2Enemy.dart';
import 'package:whisper_warriors/game/ui/mainmenu.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/abilities/abilityselectionscreen.dart';
import 'package:whisper_warriors/game/abilities/abilityfactory.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/bosses/boss1.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(UmbralFangAdapter());
  Hive.registerAdapter(VeilOfTheForgottenAdapter());
  Hive.registerAdapter(ShardOfUmbrathosAdapter());

  await Hive.openBox<InventoryItem>('inventoryBox');

  // ✅ Load equipped items **AFTER Hive is initialized**
  List<InventoryItem> loadEquippedItems() {
    final box = Hive.box<InventoryItem>('inventoryBox');

    // ✅ Retrieve **all equipped items** from stored map
    List<InventoryItem> items = box.values.cast<InventoryItem>().toList();

    print(
        "🔍 Loaded Equipped Items from Hive: ${items.map((item) => item.item.name).toList()}");

    return items;
  }

  List<InventoryItem> equippedItems = loadEquippedItems(); // ✅ Load safely

  runApp(MyApp(equippedItems: equippedItems));
}

class MyApp extends StatefulWidget {
  final List<InventoryItem> equippedItems;
  MyApp({required this.equippedItems}); // Add equippedItems
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _gameStarted = false;
  bool _selectingAbilities = false;
  bool _selectingItems = false; // New state for item selection
  List<String> selectedAbilities = [];
  List<InventoryItem> equippedItems = []; // Declare the equipped items list
  late RogueShooterGame gameInstance; // Define the gameInstance variable

  List<InventoryItem> getAvailableItems() {
    return [
      InventoryItem(
        item: UmbralFang(),
        isEquipped: false,
      ),
      InventoryItem(
        item: VeilOfTheForgotten(),
        isEquipped: false,
      ),
      InventoryItem(
        item: ShardOfUmbrathos(),
        isEquipped: false,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    equippedItems = widget.equippedItems; // Store the equipped items
  }

  void startGame() {
    print(
        "🛡 startGame() - Equipped Items Before Start: ${equippedItems.map((e) => e.item.name).toList()}");

    setState(() {
      _selectingAbilities = true;
    });
  }

  void onAbilitiesSelected(List<String> abilities) {
    setState(() {
      selectedAbilities = abilities;
      _selectingAbilities = false;
      _selectingItems =
          true; // Go to Inventory selection instead of starting the game
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
            // Main Menu
            if (!_gameStarted && !_selectingAbilities && !_selectingItems)
              MainMenu(
                startGame: startGame,
                openOptions: openOptions,
              ),

            // Ability Selection (new condition)
            if (_selectingAbilities)
              AbilitySelectionScreen(
                onAbilitiesSelected: onAbilitiesSelected,
              ),

            // Inventory selection
            if (_selectingItems)
              InventoryScreen(
                availableItems: getAvailableItems(),
                onConfirm: (finalSelectedItems) async {
                  print(
                      "🎒 Final Confirmed Items: ${finalSelectedItems.map((item) => item.item.name).toList()}");

                  final box = Hive.box<InventoryItem>('inventoryBox');
                  await box.clear(); // ✅ Ensure previous items are removed

                  // ✅ Store items properly
                  for (var item in finalSelectedItems) {
                    await box.put(item.item.name, item);
                  }

                  setState(() {
                    _selectingItems = false;
                    _gameStarted = true;
                    equippedItems = List.from(finalSelectedItems);
                  });

                  print(
                      "🛡 Equipped Items Updated in Hive: ${equippedItems.map((item) => item.item.name).toList()}");

                  gameInstance = RogueShooterGame(
                    selectedAbilities: selectedAbilities,
                    equippedItems: equippedItems,
                  );

                  // ✅ Delay applying effects to prevent null issues
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (gameInstance.player != null) {
                      gameInstance.player.applyEquippedItems();
                      print("🛡 Applied Equipped Items after Player Loaded.");
                    } else {
                      print(
                          "⚠️ Player is still null, skipping applyEquippedItems.");
                    }
                  });
                },
              ),
            // Game UI & HUD
            if (_gameStarted)
              GameWidget(
                game: gameInstance,
                overlayBuilderMap: {
                  'hud': (_, game) => HUD(
                        onJoystickMove: (delta) =>
                            (game).player.updateJoystick(delta),
                        experienceBar: (game as RogueShooterGame).experienceBar,
                        game: game,
                        bossHealthNotifier: (game).bossHealthNotifier,
                        bossStaggerNotifier: (game).bossStaggerNotifier,
                      ),
                  'retryOverlay': (_, game) =>
                      RetryOverlay(game: game as RogueShooterGame),
                },
              ),
          ],
        ),
      ),
    );
  }
}

class RogueShooterGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  late CustomCamera customCamera;
  late Player player;
  late SpiritBar experienceBar;
  late SpriteComponent grassMap;
  late TimerComponent enemySpawnerTimer;
  late TimerComponent gameTimer;
  late final AudioPlayer bgmPlayer;
  late ValueNotifier<int> gameHudNotifier;
  late ValueNotifier<double?> bossHealthNotifier;
  late ValueNotifier<double>
      bossStaggerNotifier; // ✅ Correct (Non-nullable) // ✅ Correct (Non-nullable)  int enemyCount = 0;
  int enemyCount = 0; // ✅ Add this if missing
  int maxEnemies = 30;
  final List<String> selectedAbilities;
  final List<InventoryItem> equippedItems;
  final Random random = Random(); // ✅ Define Random instance
  late LootNotificationBar lootNotificationBar;

  bool isPaused = false;
  int elapsedTime = 0;

  RogueShooterGame(
      {required this.selectedAbilities, required this.equippedItems}) {
    bossHealthNotifier = ValueNotifier<double?>(null);
    bossStaggerNotifier = ValueNotifier<double>(0); // ✅ Initialize at 0
// ✅ Initialize as null
  }
  // ✅ Stops background music
  Future<void> stopBackgroundMusic() async {
    await bgmPlayer.stop();
  }

  Future<void> playGameOverMusic() async {
    await Future.delayed(Duration(milliseconds: 500)); // Small delay
    await bgmPlayer.setReleaseMode(ReleaseMode.stop); // ✅ Ensure it plays once
    await bgmPlayer.play(AssetSource('music/game_over.mp3'));
  }

  Set<LogicalKeyboardKey> activeKeys = {}; // ✅ Track active keys

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      activeKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      activeKeys.remove(event.logicalKey);
    }

    _updatePlayerMovement(); // ✅ Update movement based on active keys

    return KeyEventResult.handled;
  }

// ✅ **Update Player Movement Based on Active Keys**
  void _updatePlayerMovement() {
    Vector2 movement = Vector2.zero();

    if (activeKeys.contains(LogicalKeyboardKey.keyW)) {
      movement.y -= 1;
    }
    if (activeKeys.contains(LogicalKeyboardKey.keyS)) {
      movement.y += 1;
    }
    if (activeKeys.contains(LogicalKeyboardKey.keyA)) {
      movement.x -= 1;
    }
    if (activeKeys.contains(LogicalKeyboardKey.keyD)) {
      movement.x += 1;
    }

    if (movement.length > 0) {
      movement.normalize(); // ✅ Prevent diagonal movement from being too fast
    }

    player.updateJoystick(movement);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // loot notification bar
    lootNotificationBar = LootNotificationBar(this);
    add(lootNotificationBar);
    print("✅ LootNotificationBar added to the game");

    bgmPlayer = AudioPlayer();
    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.play(AssetSource('music/soft_etheral.mp3'));
    await bgmPlayer.setVolume(.2);
    gameHudNotifier = ValueNotifier<int>(elapsedTime);

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

    player = Player(
      selectedAbilities: selectedAbilities, // ✅ Pass abilities
      equippedItems: equippedItems, // ✅ Ensure only equipped items are passed
    )
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
        elapsedTime++; // ✅ Increment time instead of decrementing
        gameHudNotifier.value = elapsedTime;
        triggerEvent(); // ✅ Events now trigger based on elapsed time
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

  void spawnEnemyWave(int count, {bool postBoss = false}) {
    for (int i = 0; i < count; i++) {
      final spawnPosition = _getRandomSpawnPosition();

      BaseEnemy enemy;
      if (elapsedTime >= 60) {
        // ✅ After 60 seconds, allow Wave2Enemy to spawn
        enemy = (i % 2 == 0)
            ? Wave1Enemy(
                player: player,
                speed: 70,
                health: 50,
                size: Vector2(64, 64),
              )
            : Wave2Enemy(
                player: player,
                speed: 100,
                health: 800,
                size: Vector2(128, 128),
              );
      } else {
        // ✅ Before 60 seconds, only spawn Wave1Enemy
        enemy = Wave1Enemy(
          player: player,
          speed: 100,
          health: 50,
          size: Vector2(64, 64),
        );
      }

      // ✅ **Enhance Enemies After Boss Fight**
      if (postBoss) {
        enemy.health *= 2; // 🔥 **Double Health**
        enemy.speed *= 1.5; // 🔥 **Faster Movement**
      }

      enemy.position = spawnPosition;
      enemy.onRemoveCallback = () {
        enemyCount--;
      };

      enemyCount++;
      add(enemy);
    }
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

    // ✅ Remove all existing enemies
    for (var enemy in children.whereType<BaseEnemy>()) {
      enemy.removeFromParent();
    }
    remove(enemySpawnerTimer); // ✅ Stop enemy spawns

    // ✅ Ensure the boss spawns at the **center of the game world**
    Vector2 bossSpawnPosition = Vector2(640, 640); // Adjust for your map size

    final boss = Boss1(
      player: player,
      speed: 20,
      //health: 50000,
      health: 500, // for testing purposes
      size: Vector2(128, 128),
      onHealthChanged: (double health) => bossHealthNotifier.value = health,
      onDeath: () {},
      onStaggerChanged: (double stagger) => bossStaggerNotifier.value = stagger,
      bossStaggerNotifier: bossStaggerNotifier, // ✅ NEW
// ✅ Stagger bar updates
    );

    boss.onDeath = () {
      bossHealthNotifier.value = null; // ✅ Hide Boss HP on death
      _postBossEnemySpawn();

      // ✅ Drop Gold Coin at Boss Position
      final goldCoinItem = GoldCoin();
      final goldCoin = DropItem(
        item: goldCoinItem,
      )..position = boss.position.clone();

      add(goldCoin);
      print("💰 Boss dropped a Gold Coin (5000 EXP)!");
    };

    // ✅ Set **initial boss position** outside the screen
    boss.position = Vector2(size.x / 2, -300);
    boss.anchor = Anchor.center;
    add(boss); // ✅ Add the boss to the game
    bossStaggerNotifier.value = 0; // ✅ Show stagger bar

    Future.delayed(Duration(milliseconds: 1500), () {
      // ✅ Move the boss **into the center of the map**
      boss.position = bossSpawnPosition;

      // ✅ Apply a screen shake effect
      _shakeScreen(customCamera);

      // ✅ Trigger impact effect when the boss lands
      _triggerBossImpactEffect(boss.position);

      print("🔥 BOSS LANDED IN CENTER AT $bossSpawnPosition!");
    });
    bossHealthNotifier.value = 500; // ✅ Show Boss HP for testing purposes

    //bossHealthNotifier.value = 50000; // ✅ Show Boss HP
  }

  void _postBossEnemySpawn() {
    print("🔥 Post-boss enemies now spawning!");

    // ✅ Resume enemy spawner with a **faster rate & tougher enemies**
    enemySpawnerTimer = TimerComponent(
      period: 4.0, // ✅ Faster spawn rate after boss
      repeat: true,
      onTick: () => spawnEnemyWave(12, postBoss: true), // ✅ More enemies
    );
    add(enemySpawnerTimer);
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
    if (player.isDead) {
      print("Player is dead");
      return;
    }
    print("🔹 EVENT TRIGGERED at ${formatTime(elapsedTime)}");

    if (elapsedTime == 20) {
      spawnEnemyWave(20);
      print("⚔ 00:20 - Spawned 20 enemies!");
    } else if (elapsedTime == 60) {
      print("💀 Boss is arriving, removing all enemies!");

      remove(enemySpawnerTimer);

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

  Future<void> restartGame(BuildContext context) async {
    print("🔄 Restarting game with fade effect...");

    // ✅ 1. Show Fade-To-Black Effect
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FadeTransitionOverlay(
        onFadeComplete: () async {
          Navigator.of(context).pop(); // Remove black overlay after fading in

          // ✅ 2. Clear Game Objects
          removeAll(children);
          overlays.clear();
          overlays.add('hud'); // Show HUD again

          // ✅ 3. Reset Timers & Variables
          elapsedTime = 0;
          enemyCount = 0;
          bossHealthNotifier.value = null;
          player.spiritLevel = 1;
          player.spiritExp = 0;
          player.spiritExpToNextLevel = 100;

          experienceBar.updateSpirit(
            player.spiritExp,
            player.spiritExpToNextLevel,
            player.spiritLevel,
          );

          // ✅ 4. Reset Background
          grassMap = SpriteComponent(
            sprite: await loadSprite('grass_map.png'),
            size: Vector2(1280, 1280),
            position: Vector2.zero(),
          );
          add(grassMap);

          // ✅ 5. Reset Player
          player = Player(
              selectedAbilities: selectedAbilities,
              equippedItems: equippedItems)
            ..position = Vector2(size.x / 2, size.y / 2)
            ..size = Vector2(64, 64);
          add(player);
          _applyAbilitiesToPlayer();

          // ✅ 6. Restart Background Music
          await bgmPlayer.stop();
          await bgmPlayer.setReleaseMode(ReleaseMode.loop);
          await bgmPlayer.play(AssetSource('music/soft_etheral.mp3'));
          await bgmPlayer.setVolume(.2);
          print("🎵 Background music restarted.");

          // ✅ 7. Restart Game Timers
          startEnemySpawner();
          startGameTimer();

          // ✅ 8. Fade-Back To Game (Triggered by `FadeTransitionOverlay`)
        },
      ),
    );
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

  void showNotification(String message) {
    // Implement your notification display logic here
    // For example, you can use a TextComponent or any other UI element
    add(TextComponent(
      text: message,
      position: Vector2(size.x / 2, 20), // Upper center of the screen
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 16, // Smaller font size
        ),
      ),
    ));
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
