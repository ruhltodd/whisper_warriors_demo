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
import 'package:whisper_warriors/game/ui/optionsmenu.dart';

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
  /* try {
    await Hive.openBox<InventoryItem>('inventoryBox');
    InventoryManager.initializeInventory(); // Add await here
  } catch (e) {
    print("⚠️ Database corruption detected. Attempting recovery...");
    await Hive.deleteBoxFromDisk('inventoryBox');
    await Hive.openBox<InventoryItem>('inventoryBox');
    InventoryManager.initializeInventory(); // Add await here
    print("✅ Recovery complete - fresh inventory initialized");
  } */

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
            initialRoute: '/', // Add this
            routes: {
              '/': (context) => Scaffold(
                    body: Stack(
                      children: [
                        // Main Menu
                        if (!_gameStarted &&
                            !_selectingAbilities &&
                            !_selectingItems)
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

                              final box =
                                  Hive.box<InventoryItem>('inventoryBox');

                              // Update equipped status for all items
                              for (var item in items) {
                                bool isSelected = finalSelectedItems.any(
                                    (selectedItem) =>
                                        selectedItem.item.name ==
                                        item.item.name);
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
                                    experienceBar: (game as RogueShooterGame)
                                        .experienceBar,
                                    game: game,
                                    bossHealthNotifier:
                                        (game).bossHealthNotifier,
                                    bossStaggerNotifier:
                                        (game).bossStaggerNotifier,
                                  ),
                              'retryOverlay': (_, game) =>
                                  RetryOverlay(game: game as RogueShooterGame),
                            },
                          ),
                      ],
                    ),
                  ),
            },
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
  late ValueNotifier<dynamic> gameHudNotifier;
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

  Set<LogicalKeyboardKey> activeKeys =
      {}; // Add this property to track active keys

  RogueShooterGame(
      {required this.selectedAbilities, required this.equippedItems}) {
    bossHealthNotifier = ValueNotifier<double?>(null);
    bossStaggerNotifier = ValueNotifier<double>(0); // ✅ Initialize at 0
    activeBossNameNotifier = ValueNotifier<String?>(null);

// ✅ Initialize as null
  }
  // ✅ Stops background music
  Future<void> stopBackgroundMusic() async {
    try {
      await bgmPlayer.stop().timeout(
        Duration(seconds: 2),
        onTimeout: () {
          print("⚠️ Background music stop timed out");
          return;
        },
      );
    } catch (e) {
      print("❌ Error stopping background music: $e");
    }
  }

  Future<void> playGameOverMusic() async {
    await Future.delayed(Duration(milliseconds: 500)); // Small delay
    await bgmPlayer.setReleaseMode(ReleaseMode.stop); // ✅ Ensure it plays once
    await bgmPlayer.play(AssetSource('music/game_over.mp3'));
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Always handle key events to prevent system sounds
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (overlays.isActive('optionsMenu')) {
          overlays.remove('optionsMenu');
          resumeEngine();
        } else {
          overlays.add('optionsMenu');
          pauseEngine();
        }
      }
      activeKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      activeKeys.remove(event.logicalKey);
    }

    // Update player movement based on active keys
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
      movement.normalize(); // Prevent diagonal movement from being too fast
    }

    player.updateJoystick(movement);

    // Return handled for all key events to prevent system sounds
    return KeyEventResult.handled;
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
    gameHudNotifier = ValueNotifier<dynamic>(elapsedTime);

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

    overlays.addEntry(
      'optionsMenu',
      (context, game) => OptionsMenu(game: game as RogueShooterGame),
    );

    overlays.addEntry(
      'damageReport',
      (context, game) => ValueListenableBuilder<dynamic>(
        valueListenable: gameHudNotifier,
        builder: (context, value, _) {
          if (value is String) {
            return Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () => (game as RogueShooterGame)
                              .quitToMainMenu(context),
                          child: const Text('Quit to Main Menu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
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

  void quitToMainMenu(BuildContext context) {
    print("🛑 Starting game cleanup sequence...");

    // First pause the game engine
    pauseEngine();
    print("⏸️ Game engine paused");

    // Store context reference
    final navigatorContext = context;

    try {
      print("🧹 Beginning cleanup...");

      // Remove all overlays
      print("🎭 Removing overlays...");
      overlays.clear();
      print("✅ Overlays removed");

      // Stop background music
      print("🎵 Stopping background music...");
      stopBackgroundMusic();
      print("✅ Background music stopped");

      // Remove all game components
      print("🎮 Removing game components...");
      removeAll(children);
      print("✅ Game components removed");

      // Stop the ticker
      print("⏱️ Stopping game ticker...");
      _ticker.stop();
      print("✅ Ticker stopped");

      // Reset game state
      print("🔄 Resetting game state...");
      spawnController = null;
      elapsedTime = 0;
      enemyCount = 0;
      _elapsedTime = 0.0;
      print("✅ Game state reset");

      // Reset all notifiers
      print("📢 Resetting notifiers...");
      gameHudNotifier.dispose(); // Properly dispose notifiers
      bossHealthNotifier.dispose();
      bossStaggerNotifier.dispose();
      activeBossNameNotifier.dispose();
      print("✅ Notifiers disposed");

      // Ensure we're detached
      print("🔌 Detaching game...");
      onRemove();
      print("✅ Game detached");

      print("🚀 Attempting navigation...");

      if (navigatorContext.mounted) {
        // Navigate back to root with a fresh state
        Navigator.of(navigatorContext).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MaterialApp(
              debugShowCheckedModeBanner: false, // Remove debug banner
              home: Scaffold(
                body: _LoadingScreen(),
              ),
            ),
          ),
          (route) => false,
        );
        print("✅ Navigation complete");
      } else {
        print("⚠️ Context not mounted");
      }
    } catch (e, stackTrace) {
      print("❌ Error during cleanup: $e");
      print("📚 Stack trace: $stackTrace");
    }
  }

  void navigateToMainMenu(BuildContext context) {
    // First cleanup the game
    quitToMainMenu(context);

    // Ensure we're completely detached before navigation
    onRemove();

    // Use a delayed microtask to ensure complete cleanup
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  @override
  void onRemove() {
    super.onRemove();
    _ticker.stop(); // Ensure ticker is stopped when game is removed
  }

  Future<void> restartGame(BuildContext context) async {
    print("🔄 Starting game restart sequence...");

    // First pause and cleanup
    pauseEngine();
    print("⏸️ Game engine paused");

    try {
      // Remove all overlays except retry
      print("🎭 Removing overlays...");
      overlays.clear();
      print("✅ Overlays removed");

      // Stop background music
      print("🎵 Stopping background music...");
      await stopBackgroundMusic();
      print("✅ Background music stopped");

      // Remove all game components
      print("🎮 Removing game components...");
      removeAll(children);
      print("✅ Game components removed");

      // Reset game state
      print("🔄 Resetting game state...");
      spawnController = null;
      elapsedTime = 0;
      enemyCount = 0;
      _elapsedTime = 0.0;

      // Reset all notifiers
      gameHudNotifier.value = 0;
      bossHealthNotifier.value = null;
      bossStaggerNotifier.value = 0;
      activeBossNameNotifier.value = null;
      print("✅ Game state reset");

      // Initialize new game
      print("🎮 Initializing new game...");
      await onLoad();
      print("✅ New game initialized");

      // Resume engine
      resumeEngine();
      print("▶️ Game engine resumed");

      print("✨ Game restart complete!");
    } catch (e, stackTrace) {
      print("❌ Error during restart: $e");
      print("📚 Stack trace: $stackTrace");

      // If restart fails, return to main menu
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void showDamageReport() {
    print("📊 Generating damage report...");

    String report = "📊 Damage Report\n";
    report += "================\n\n";

    // Collect all damage reports
    final reports = <DamageReport>[];

    // Get reports from active abilities
    print("🎯 Collecting ability damage reports...");
    for (var ability in player.getAbilities()) {
      reports.add(ability.damageReport);
    }

    // Sort by total damage
    reports.sort((a, b) => b.totalDamage.compareTo(a.totalDamage));

    // Build report string
    for (var damageReport in reports) {
      report += "${damageReport.toString()}\n";
    }

    // Calculate total damage across all abilities
    int totalGameDamage =
        reports.fold(0, (sum, report) => sum + report.totalDamage);
    report += "\n🔥 Total Game Damage: $totalGameDamage\n";

    print("📝 Damage report generated:");
    print(report);

    // Pause game and show report
    pauseEngine();
    overlays.add('damageReport');
    gameHudNotifier.value = report;
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      final items = await loadInventoryItems();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyApp(inventoryItems: items),
          ),
        );
      }
    } catch (e) {
      print("❌ Error loading game: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
