import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whisper_warriors/game/ai/spawncontroller.dart';
import 'package:whisper_warriors/game/inventory/inventory.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/itemselectionscreen.dart';
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'dart:math';
import 'package:whisper_warriors/game/ui/spiritlevelbar.dart';
import 'package:whisper_warriors/game/ui/notifications.dart';
import 'package:whisper_warriors/game/utils/customcamera.dart';
import 'package:whisper_warriors/game/ui/hud.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ui/mainmenu.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/abilities/abilityselectionscreen.dart';
import 'package:whisper_warriors/game/abilities/abilityfactory.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';

Future<List<InventoryItem>> loadInventoryItems() async {
  // Renamed for clarity
  try {
    // Ensure the box is open before trying to access it
    if (!Hive.isBoxOpen('inventoryBox')) {
      await Hive.openBox<InventoryItem>('inventoryBox');
      InventoryManager.initializeInventory();
    }

    final box = Hive.box<InventoryItem>('inventoryBox');
    List<InventoryItem> allItems = box.values.cast<InventoryItem>().toList();

    // Split into equipped and unequipped items
    List<InventoryItem> equippedItems =
        allItems.where((item) => item.isEquipped).toList();

    print(
        "🔍 Loaded ALL Items from Hive: ${allItems.map((item) => item.item.name).toList()}");
    print(
        "⚔️ Currently Equipped: ${equippedItems.map((item) => item.item.name).toList()}");

    return allItems; // Return all items, not just equipped ones
  } catch (e) {
    print("⚠️ Error loading inventory items: $e");
    return [];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('playerProgressBox');
  /*// Uncomment to reset progress on every launch
  PlayerProgressManager.resetProgressForTestingTemporary();
  // ✅ TEST: Set initial XP & Level if not already stored

  if (PlayerProgressManager.getXp() == 0) {
    PlayerProgressManager.setXp(50);
  }
  if (PlayerProgressManager.getLevel() == 1) {
    PlayerProgressManager.setLevel(1);
  } */

  print("🌟 Player XP: ${PlayerProgressManager.getXp()}");
  print("🌟 Player Level: ${PlayerProgressManager.getLevel()}");

  // Register Hive adapters
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(UmbralFangAdapter());
  Hive.registerAdapter(VeilOfTheForgottenAdapter());
  Hive.registerAdapter(ShardOfUmbrathosAdapter());
  Hive.registerAdapter(GoldCoinAdapter()); // ✅ Register GoldCoin
  Hive.registerAdapter(BlueCoinAdapter()); // ✅ Register BlueCoin
  //await Hive.deleteBoxFromDisk('inventoryBox'); remove database and start game is .clear() doesnt work.. for debugging only
  //final inventoryBox = await Hive.openBox<InventoryItem>('inventoryBox'); if debugging and removing database uncomment this line and comment the next line
  try {
    await Hive.openBox<InventoryItem>('inventoryBox');
    InventoryManager.initializeInventory(); // Add await here
  } catch (e) {
    print("⚠️ Database corruption detected. Attempting recovery...");
    await Hive.deleteBoxFromDisk('inventoryBox');
    await Hive.openBox<InventoryItem>('inventoryBox');
    InventoryManager.initializeInventory(); // Add await here
    print("✅ Recovery complete - fresh inventory initialized");
  }

  //await Hive.box('inventoryBox').clear(); ✅ Clear box before adding items - for debugging only
  //await Hive.box('playerProgressBox').clear(); ✅ Clears progress
  //print("debug inventory wiped on startup");

  // Load ALL inventory items
  List<InventoryItem> inventoryItems = await loadInventoryItems();
  runApp(MyApp(inventoryItems: inventoryItems)); // Rename parameter to match
}

class MyApp extends StatefulWidget {
  final List<InventoryItem> inventoryItems;
  MyApp({required this.inventoryItems});
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

  @override
  void initState() {
    super.initState();
    equippedItems = widget.inventoryItems; // Store the equipped items
  }

  Future<List<InventoryItem>> getAvailableItems() async {
    try {
      // Ensure the box is open
      if (!Hive.isBoxOpen('inventoryBox')) {
        await Hive.openBox<InventoryItem>('inventoryBox');
      }

      final box = Hive.box<InventoryItem>('inventoryBox');
      return box.values.toList();
    } catch (e) {
      print("⚠️ Error getting available items: $e");
      return [];
    }
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
    return FutureBuilder<List<InventoryItem>>(
        future: getAvailableItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Or your loading widget
          }

          final items = snapshot.data ?? [];
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
                      availableItems: items,
                      onConfirm: (finalSelectedItems) async {
                        print(
                            "🎒 Final Confirmed Items: ${finalSelectedItems.map((item) => item.item.name).toList()}");

                        final box = Hive.box<InventoryItem>('inventoryBox');

                        // Update equipped status for all items
                        for (var item in items) {
                          bool isSelected = finalSelectedItems.any(
                              (selectedItem) =>
                                  selectedItem.item.name == item.item.name);
                          item.isEquipped = isSelected;
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
                          gameInstance.player.applyEquippedItems();
                          debugPrint(
                              "🛡 Applied Equipped Items after Player Loaded.");
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
                              experienceBar:
                                  (game as RogueShooterGame).experienceBar,
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
        });
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
  late LootNotificationBar lootNotificationBar;
  late final AudioPlayer bgmPlayer;
  late ValueNotifier<int> gameHudNotifier;
  late ValueNotifier<double?> bossHealthNotifier;
  late ValueNotifier<double> bossStaggerNotifier; // ✅ Correct (Non-nullable)
  late ValueNotifier<String?> activeBossNameNotifier;
  late Ticker _ticker;
  double _elapsedTime = 0.0;
  final double targetFps = 60.0;
  final double targetTimeStep = 1 / 60.0; // ✅ Add this line
  int enemyCount = 0;
  int maxEnemies = 30;
  double maxBossHealth = 50000; // ✅ Default value
  final List<String> selectedAbilities;
  final List<InventoryItem> equippedItems;
  final Random random = Random(); // ✅ Define Random instance

  SpawnController? spawnController;

  bool isPaused = false;
  int elapsedTime = 0;

  RogueShooterGame(
      {required this.selectedAbilities, required this.equippedItems}) {
    bossHealthNotifier = ValueNotifier<double?>(null);
    bossStaggerNotifier = ValueNotifier<double>(0); // ✅ Initialize at 0
    activeBossNameNotifier = ValueNotifier<String?>(null);

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
    // Start the ticker to control frame rate
    _ticker = Ticker(_onTick);
    _ticker.start();
    //debugMode = true; // ✅ Show hitboxes and outlines
    gameTimer = TimerComponent(period: 1.0, repeat: true, onTick: () {});
    // ✅ Now safely start the timer
    startGameTimer();
// ✅ Ensure this runs when the game starts
    // ✅ Loot notification bar
    lootNotificationBar = LootNotificationBar(this);
    add(lootNotificationBar);
    print("✅ LootNotificationBar added to the game");

    // ✅ Background music setup
    bgmPlayer = AudioPlayer();
    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.play(AssetSource('music/soft_etheral.mp3'));
    await bgmPlayer.setVolume(.0);

    // ✅ Initialize HUD notifier
    gameHudNotifier = ValueNotifier<int>(elapsedTime);

    // ✅ Initialize custom camera
    customCamera = CustomCamera(
      screenSize: size, // Ensure screen size is passed
      worldSize: Vector2(1280, 1280), // Set the world size
    );

    // ✅ Load the game map
    grassMap = SpriteComponent(
      sprite: await loadSprite('grass_map.png'),
      size: Vector2(1280, 1280),
      position: Vector2.zero(),
    );
    add(grassMap);

    // ✅ Create and add player
    player = Player(
      selectedAbilities: selectedAbilities, // ✅ Pass abilities
      equippedItems: equippedItems, // ✅ Ensure only equipped items are passed
    )
      ..position = Vector2(size.x / 2, size.y / 2)
      ..size = Vector2(64, 64);
    add(player);

    _applyAbilitiesToPlayer();

    // ✅ Initialize spirit/XP bar
    experienceBar = SpiritBar();
    customCamera.follow(player.position, 0);

    // ✅ Show HUD
    overlays.add('hud');

    // ✅ Initialize the Spawn Controller (Handles all spawns now)
    spawnController = SpawnController(game: this);
    if (spawnController != null) {
      add(spawnController!);
    }
  }

  void _onTick(Duration elapsed) {
    // Calculate elapsed time in seconds
    _elapsedTime += elapsed.inMicroseconds / 1000000.0;

    // Update game logic at 60 FPS
    if (_elapsedTime >= targetTimeStep) {
      _updateGameLogic();
      _elapsedTime = 0.0;
    }
  }

  void _updateGameLogic() {
    // Your game update logic goes here (e.g., movement, collisions, etc.)
    // This will only run at a maximum of 60 FPS
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
    print("🎮 Applying only selected abilities: $selectedAbilities");

    // Clear any existing abilities first
    player.clearAbilities();

    // Only apply the abilities that were specifically selected
    for (String abilityName in selectedAbilities) {
      Ability? ability = AbilityFactory.createAbility(abilityName);
      if (ability != null) {
        player.addAbility(ability);
        print("✅ Added ability: $abilityName");
      }
    }

    print(
        "✨ Final player abilities: ${player.getAbilities().map((a) => a.name).toList()}");
  }

  void startGameTimer() {
    gameTimer = TimerComponent(
      period: 1.0, // ✅ Fires every 1 second
      repeat: true,
      onTick: () {
        elapsedTime++; // ✅ Increment time
        gameHudNotifier.value = elapsedTime;
        spawnController
            ?.checkAndTriggerEvents(elapsedTime); // ✅ Calls event logic
      },
    );
    add(gameTimer);
  }

  void _stopEnemySpawns() {
    if (enemySpawnerTimer.isMounted) {
      remove(enemySpawnerTimer);
      print("🛑 Enemy spawns stopped.");
    }
  }

  void shakeScreen(CustomCamera camera) {
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

  void setActiveBoss(String name, double maxHealth) {
    activeBossNameNotifier.value = name;
    bossHealthNotifier.value = maxHealth;
    maxBossHealth = maxHealth; // ✅ Store max HP separately
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}"; // Ensures two-digit seconds
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
          await bgmPlayer.setVolume(0);
          print("🎵 Background music restarted.");

          // ✅ 7. Restart Spawn Controller (Handles enemy & boss spawns)
          spawnController = SpawnController(game: this);
          if (spawnController != null) {
            add(spawnController!);
          }

          // ✅ 8. Restart Game Timer (Events handled inside SpawnController)
          startGameTimer();

          print("✅ Game Restarted!");
        },
      ),
    );
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

  @override
  void onRemove() {
    super.onRemove();
    _ticker.stop(); // Ensure ticker is stopped when game is removed
  }
}
