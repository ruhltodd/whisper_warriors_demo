import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/scheduler.dart';
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whisper_warriors/game/ai/spawncontroller.dart';
import 'package:whisper_warriors/game/damage/ability_damage_log.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/itemselectionscreen.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';
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
import 'package:whisper_warriors/game/damage/damage_tracker.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/ui/textstyles.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';
import 'package:whisper_warriors/game/ui/screentransition.dart';
import 'package:whisper_warriors/game/ui/game_viewport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  const String progressBoxName = 'playerprogressbox';
  if (!Hive.isBoxOpen(progressBoxName)) {
    await Hive.openBox(progressBoxName);
    print('📦 Opened progress box');
  }

  // Initialize managers
  await PlayerProgressManager.initialize();
  print('✅ Hive initialization complete');

  if (PlayerProgressManager.getXp() == 0) {
    PlayerProgressManager.setXp(50);
  }
  if (PlayerProgressManager.getLevel() == 1) {
    PlayerProgressManager.setLevel(1);
  }

  print("🌟 Player XP: ${PlayerProgressManager.getXp()}");
  print("🌟 Player Level: ${PlayerProgressManager.getLevel()}");

  // Initialize damage tracking
  await DamageTracker.initialize();

  print('📦 Loading inventory...');
  final items = await InventoryStorage.loadInventory();
  print('✅ Loaded ${items.length} items');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RogueShooterGame? gameInstance;

  @override
  void initState() {
    super.initState();
  }

  void startGame(BuildContext context) {
    // Clear damage logs
    Hive.box<AbilityDamageLog>('ability_damage_logs').clear();
    Navigator.pushNamed(context, '/ability_selection');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
      ),
      navigatorKey: GlobalKey<NavigatorState>(),
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(
              backgroundColor: Colors.black,
              body: GameViewport(
                child: ClipRect(
                  child: gameInstance == null
                      ? MainMenu(
                          startGame: () => startGame(context),
                        )
                      : GameWidget.controlled(
                          gameFactory: () => gameInstance!,
                          loadingBuilder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          backgroundBuilder: (context) => Container(
                            color: Colors.black,
                          ),
                          overlayBuilderMap: {
                            'hud': (_, game) => HUD(
                                  onJoystickMove: (delta) =>
                                      (game).player.updateJoystick(delta),
                                  experienceBar:
                                      (game as RogueShooterGame).experienceBar,
                                  game: game,
                                  bossHealthNotifier: (game).bossHealthNotifier,
                                  bossStaggerNotifier:
                                      (game).bossStaggerNotifier,
                                ),
                            'retryOverlay': (_, game) => RetryOverlay(
                                  game: game as RogueShooterGame,
                                ),
                            'optionsMenu': (_, game) => OptionsMenu(
                                  game: game as RogueShooterGame?,
                                ),
                            'damageReport': (_, game) => DamageReportOverlay(
                                  game: game as RogueShooterGame,
                                ),
                            'playerStatsOverlay': (_, game) =>
                                PlayerStatsOverlay(
                                  player: gameInstance!.player,
                                  game: gameInstance!,
                                ),
                          },
                        ),
                ),
              ),
            ),
        '/ability_selection': (context) => Scaffold(
              backgroundColor: Colors.black,
              body: GameViewport(
                child: AbilitySelectionScreen(
                  onAbilitiesSelected: (abilities) async {
                    final availableItems =
                        await InventoryStorage.loadInventory();

                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/item_selection',
                        arguments: {
                          'abilities': abilities,
                          'availableItems': availableItems,
                        },
                      );
                    }
                  },
                ),
              ),
            ),
        '/item_selection': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return Scaffold(
            backgroundColor: Colors.black,
            body: GameViewport(
              child: InventoryScreen(
                availableItems: args['availableItems'],
                onConfirm: (selectedItems) async {
                  print(
                      "🎒 Selected Items: ${selectedItems.map((item) => item.name).toList()}");

                  // Update equipped status
                  final items = await InventoryStorage.loadInventory();
                  for (var item in items) {
                    item.isEquipped = selectedItems
                        .any((selected) => selected.name == item.name);
                  }
                  await InventoryStorage.saveInventory(items);

                  if (context.mounted) {
                    setState(() {
                      gameInstance = RogueShooterGame(
                        selectedAbilities: args['abilities'],
                        equippedItems: selectedItems,
                      );
                    });

                    // Pop back to root
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
          );
        },
      },
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
  late LootNotificationBar lootNotificationBar;
  late final AudioPlayer bgmPlayer = AudioPlayer();
  late final ValueNotifier<dynamic> gameHudNotifier =
      ValueNotifier<dynamic>(null);
  ValueNotifier<double> bossHealthNotifier =
      ValueNotifier(1.0); // Non-nullable double
  late final ValueNotifier<double> bossStaggerNotifier =
      ValueNotifier<double>(0.0);
  late final ValueNotifier<String?> activeBossNameNotifier =
      ValueNotifier<String?>(null);
  late final ValueNotifier<String?> bossNameNotifier =
      ValueNotifier<String?>(null);
  Ticker? _ticker;
  static const double targetFps = 60.0;
  static const double timeStep = 1.0 / targetFps;
  double _accumulator = 0.0;
  double _elapsedTime = 0.0;
  int enemyCount = 0;
  int maxEnemies = 30;
  double maxBossHealth = 50000;
  final List<String> selectedAbilities;
  final List<InventoryItem> equippedItems;
  final Random random = Random();
  final Vector2 screenSize = Vector2(820, 820);

  SpawnController? spawnController;
  bool isPaused = false;
  int elapsedTime = 0;
  Set<LogicalKeyboardKey> activeKeys = {};
  late final LootNotificationBar notificationBar;
  bool hasInitialized = false;

  // Add flags to track if notifiers are disposed
  bool _notifiersDisposed = false;

  bool _isRunning = false;

  RogueShooterGame({
    required this.selectedAbilities,
    required this.equippedItems,
  });
  @override
  void onGameResize(Vector2 screenSize) {
    super.onGameResize(Vector2(820, 820)); // ✅ Lock resolution
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    hasInitialized = true;
    try {
      print('🎮 Starting game initialization...');

      // Initialize DamageTracker first
      print('📊 Initializing DamageTracker...');
      await DamageTracker.clearAllDamageData();

      // ✅ Initialize camera inside onLoad
      print('🎥 Initializing camera...');
      customCamera = CustomCamera(
        rawScreenSize: screenSize, // ✅ Now size is ready
        worldSize: Vector2(1280, 1280),
      );

      // Load and add grass map
      print('🗺️ Loading grass map...');
      grassMap = SpriteComponent(
        sprite: await loadSprite('grass_map.png'),
        size: Vector2(1280, 1280),
        position: Vector2.zero(),
      );
      add(grassMap);

      // Initialize player
      print('👤 Initializing player...');
      player = Player(
        selectedAbilities: selectedAbilities,
        equippedItems: equippedItems,
      )
        ..position = Vector2(1280 / 2, 1280 / 2)
        ..size = Vector2(64, 64);
      add(player);

      // Initialize experience bar
      print('✨ Initializing experience bar...');
      experienceBar = SpiritBar();

      // Apply abilities to player
      print('🔥 Applying abilities...');
      _applyAbilitiesToPlayer();

      // Initialize spawn controller
      print('👾 Initializing spawn controller...');
      spawnController = SpawnController(game: this);
      add(spawnController!);

      // Initialize game timer
      print('⏱️ Initializing game timer...');
      startGameTimer();

      // Initialize notifications
      print('📢 Initializing notifications...');
      lootNotificationBar = LootNotificationBar(this);
      add(lootNotificationBar);

      // Initialize audio
      print('�� Initializing audio...');
      final audioManager = AudioManager();
      await audioManager.preloadAudio();
      await audioManager.playBackgroundMusic('audio/soft_etheral.mp3');

      // Initialize notifiers
      print('📱 Initializing notifiers...');
      gameHudNotifier.value = elapsedTime;
      bossHealthNotifier.value = 1.0;
      bossStaggerNotifier.value = 0.0;
      activeBossNameNotifier.value = null;
      bossNameNotifier.value = null;

      // Add overlays
      print('🎭 Adding overlays...');
      overlays.add('hud');

      print('✅ Game initialization complete');
    } catch (e, stackTrace) {
      print('❌ Error in game initialization: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _onTick(Duration elapsed) {
    // Calculate elapsed time in seconds
    _elapsedTime += elapsed.inMicroseconds / 1000000.0;

    // Update game logic at 60 FPS
    if (_elapsedTime >= timeStep) {
      _updateGameLogic();
      _elapsedTime = 0.0;
    }
  }

  void _updateGameLogic() {
    if (!isPaused && spawnController != null) {
      spawnController!.checkAndTriggerEvents(elapsedTime);
    }

    // Update player movement and other game logic
    if (player.isMounted) {
      player.updateMovement(timeStep);
    }

    if (player.isMounted) {
      experienceBar = SpiritBar();
    }

    // Update camera if needed
    if (player.isMounted) {
      customCamera.follow(player.position, timeStep);
    }
  }

  @override
  void update(double dt) {
    if (isPaused) return;

    // Accumulate time
    _accumulator += dt;

    // Update in fixed time steps
    while (_accumulator >= timeStep) {
      try {
        // Update spawn controller
        if (spawnController != null) {
          spawnController!.checkAndTriggerEvents(elapsedTime);
        }

        // Update player
        if (player.isMounted) {
          player.update(timeStep); // Use fixed timeStep instead of dt
        }

        // Update camera
        if (player.isMounted && customCamera != null) {
          customCamera.follow(player.position, timeStep); // Use fixed timeStep
        }

        super.update(timeStep); // Use fixed timeStep
        _accumulator -= timeStep;
      } catch (e) {
        print('❌ Error in update: $e');
      }
    }
  }

  @override
  void render(Canvas canvas) {
    try {
      if (customCamera != null) {
        canvas.save();
        customCamera.applyTransform(canvas);
        super.render(canvas);
        canvas.restore();
      } else {
        super.render(canvas);
      }
    } catch (e) {
      print('❌ Error in render: $e');
    }
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

  void navigateToMainMenu(BuildContext context) async {
    try {
      print('🔄 Starting main menu navigation...');

      // First cleanup the game
      await quitToMainMenu(context);

      // Call onRemove without await since it's void
      onRemove();

      // Use MaterialPageRoute for a clean transition
      if (context.mounted) {
        print('🎯 Navigating to main menu...');
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainMenu(
              startGame: () {
                print("🎮 Starting new game...");
                // Add your start game logic here
              },
            ),
          ),
          (route) => false, // Remove all previous routes
        );
        print('✅ Navigation complete');
      }
    } catch (e, stackTrace) {
      print('❌ Navigation error: $e');
      print('📚 Stack trace: $stackTrace');
    }
  }

  Future<void> quitToMainMenu(BuildContext context) async {
    print("🛑 Starting game cleanup sequence...");

    // Store and log initial context state
    final isInitiallyMounted = context.mounted;
    print("📌 Initial context mounted state: $isInitiallyMounted");

    if (!isInitiallyMounted) {
      print("⚠️ Context not mounted at start of cleanup");
      return;
    }

    // First pause the game engine
    pauseEngine();
    print("⏸️ Game engine paused");

    // Try to navigate FIRST, before any cleanup
    print("🚀 Attempting early navigation...");
    if (context.mounted) {
      try {
        final navigatorState = Navigator.of(context);
        await navigatorState.pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const _LoadingScreen(),
            transitionDuration: Duration.zero,
          ),
          (route) => false,
        );
        print("✅ Navigation scheduled");
      } catch (navError) {
        print("❌ Early navigation error: $navError");
      }
    }

    try {
      print("🧹 Beginning cleanup...");

      // Remove all overlays
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
      print("✅ Game state reset");

      // Reset all notifiers
      print("📢 Resetting notifiers...");
      gameHudNotifier.value = null;
      bossHealthNotifier.value = 1.0;
      bossStaggerNotifier.value = 0;
      activeBossNameNotifier.value = null;
      bossNameNotifier.value = null;
      print("✅ Notifiers reset");

      // Finally detach the game
      print("🔌 Detaching game...");
      onRemove();
      print("✅ Game detached");
    } catch (e, stackTrace) {
      print("❌ Error during cleanup: $e");
      print("📚 Stack trace: $stackTrace");
    }
  }

  @override
  void onRemove() {
    if (!_notifiersDisposed) {
      try {
        bossHealthNotifier.dispose();
        bossStaggerNotifier.dispose();
        experienceBar.dispose();
        // Any other notifiers...

        _notifiersDisposed = true;
        print('🎮 Game notifiers disposed safely');
      } catch (e) {
        print('⚠️ Warning: Some notifiers were already disposed');
      }
    }

    super.onRemove();
  }

  Future<void> restartGame(BuildContext context) async {
    print("🔄 Starting game restart sequence...");

    // First pause and cleanup
    pauseEngine();
    print("⏸️ Game engine paused");

    try {
      // Remove all overlays except retry
      print("🎭 Removing overlays...");
      final currentOverlays = overlays.activeOverlays.toList();
      for (final overlay in currentOverlays) {
        if (overlay != 'retryOverlay') {
          overlays.remove(overlay);
        }
      }
      print("✅ Overlays handled");

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
      bossHealthNotifier.value = 1.0;
      bossStaggerNotifier.value = 0;
      activeBossNameNotifier.value = null;
      bossNameNotifier.value = null;
      print("✅ Game state reset");

      // Re-initialize game components
      print("🎮 Reinitializing game components...");
      await onLoad();
      print("✅ Game components reinitialized");

      // Add back necessary overlays
      overlays.add('hud');
      overlays.remove('retryOverlay');

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

  void showPlayerStats() {
    print("Showing player stats...");
    overlays.add('playerStatsOverlay');
  }

  void showDamageReport() {
    DamageTracker tracker = DamageTracker('report');
    String report = tracker.generateDamageReport();
    print(report);
    // Pause game and show report
    pauseEngine();
    overlays.add('damageReport');
    gameHudNotifier.value = report;
  }

  void onItemCollected(Item item) async {
    try {
      final inventory = await InventoryStorage.loadInventory();

      // Remove existing duplicate before adding new item
      inventory.removeWhere((invItem) => invItem.item.name == item.name);

      // Check for available slots
      bool hasOpenSlot = inventory.length < InventoryStorage.maxSlots;

      if (!hasOpenSlot) {
        print('⛔ Inventory is full, cannot collect ${item.name}');
        showNotification(
            'Inventory full! Cannot collect: ${item.name}', item.rarity);
        return;
      }

      // Add the new item
      final inventoryItem = InventoryItem(
        item: item,
        isNew: true,
        quantity: 1,
        isEquipped: false, // ✅ Never auto-equip if already owned
      );

      inventory.add(inventoryItem);
      await InventoryStorage.saveInventory(inventory);

      print('✨ Collected and replaced duplicate: ${item.name}');
      showNotification('Item updated: ${item.name}', item.rarity);

      await AudioPlayer().play(AssetSource('audio/collect_item.mp3'));
    } catch (e) {
      print('❌ Error collecting item: $e');
    }
  }

  void showNotification(String message, ItemRarity rarity) {
    notificationBar.showNotification(message, rarity);
  }

  Future<void> stopBackgroundMusic() async {
    try {
      print('🎵 Stopping background music...');
      final audioManager = AudioManager();
      await audioManager.stopBackgroundMusic();
      print('✅ Background music stopped');
    } catch (e) {
      print('❌ Error stopping background music: $e');
    }
  }

  Future<void> playGameOverMusic() async {
    try {
      print('🎵 Playing game over music...');
      final audioManager = AudioManager();
      await audioManager.playGameOverMusic();
      print('✅ Game over music started');
    } catch (e) {
      print('❌ Error playing game over music: $e');
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Update active keys
    if (event is KeyDownEvent) {
      activeKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      activeKeys.remove(event.logicalKey);
    }

    // Handle ESC key for options menu
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (!isPaused) {
          pauseGame();
          overlays.add('optionsMenu');
        } else {
          resumeGame();
          overlays.remove('optionsMenu');
        }
        return KeyEventResult.handled;
      }
    }

    // Handle WASD/Arrow keys for movement
    if (player.isMounted) {
      Vector2 movement = Vector2.zero();

      // Check active keys and update movement vector
      if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        movement.y -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
          keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        movement.y += 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
          keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        movement.x -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
          keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        movement.x += 1;
      }

      // If there's movement, normalize it
      if (movement != Vector2.zero()) {
        movement.normalize();
      }

      // Always update the joystick, even with zero movement
      player.updateJoystick(movement);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // Add this method to track active keys
  bool isKeyPressed(LogicalKeyboardKey key) {
    return activeKeys.contains(key);
  }

  void pauseGame() {
    isPaused = true;
    pauseEngine();
    print('⏸️ Game paused');
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine();
    print('▶️ Game resumed');
  }

  // Update boss info
  void updateBossInfo(String name, double health, double maxHealth) {
    bossNameNotifier.value = name;
    bossHealthNotifier.value = health;
    maxBossHealth = maxHealth;
  }

  void resumeEngine() {
    if (!_isRunning) {
      _isRunning = true;
      print("Game resumed");
    }
  }

  void pauseEngine() {
    _isRunning = false;
    print("Game paused");
  }

  bool get isRunning => _isRunning;

  void victory() {
    print('🏆 Victory!');
    pauseEngine();
    overlays.add('damageReport');
  }
}

class RetryOverlay extends StatelessWidget {
  final RogueShooterGame game;

  const RetryOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Game Over',
            style: GameTextStyles.gameTitle(
              fontSize: 48,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.purple.shade900,
            ),
            onPressed: () => game.restartGame(context),
            child: Text(
              'Try Again',
              style: GameTextStyles.gameTitle(
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.purple.shade900,
            ),
            onPressed: () => game.navigateToMainMenu(context),
            child: Text(
              'Main Menu',
              style: GameTextStyles.gameTitle(
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
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
      final items = await InventoryStorage.loadInventory();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyApp(),
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

class DamageReportOverlay extends StatelessWidget {
  final RogueShooterGame game;

  const DamageReportOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(30),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Damage Report',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: ValueListenableBuilder(
                  valueListenable: game.gameHudNotifier,
                  builder: (context, value, child) {
                    final damageTracker = DamageTracker('report');
                    final logs = damageTracker.getAllLogs();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logs.map((log) {
                        double critRate = log.hits > 0
                            ? (log.criticalHits / log.hits) * 100
                            : 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.abilityName}:',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'Total Damage: ${log.totalDamage}',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'Hits: ${log.hits}',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'Critical Hits: ${log.criticalHits}',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              'Crit Rate: ${critRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                game.resumeEngine();
                game.overlays.remove('damageReport');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
