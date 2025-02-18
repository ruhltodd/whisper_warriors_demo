import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/abilities/abilityfactory.dart';
import 'package:whisper_warriors/game/player/healthbar.dart';
import 'package:whisper_warriors/game/inventory/inventory.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/abilities/passives.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/player/whisperwarrior.dart';
import 'package:whisper_warriors/game/effects/healingnumber.dart';
import 'package:whisper_warriors/game/abilities/abilities.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/damage/damage_tracker.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final DamageTracker damageTracker =
      DamageTracker('player'); // Add ability name

  // Base stats
  static const double DEFAULT_SPEED = 140.0;
  static const double DEFAULT_DAMAGE = 10.0;
  static const double DEFAULT_ATTACK_COOLDOWN = 1.0;

  // Current stats
  double speed = DEFAULT_SPEED;
  double baseDamage = DEFAULT_DAMAGE;
  double attackCooldown = DEFAULT_ATTACK_COOLDOWN;

  // Base Stats (before Spirit Level modifications)
  double baseHealth = 100.0;
  double baseSpeed = 100.0;
  double baseAttackSpeed = 1.0; // Base attack speed
  double baseDefense = 0.0; // % Damage reduction
  double baseCritChance = 5.0; // Base crit chance at 5%
  double baseCritMultiplier = 1.5; // 1.5x damage on crit

  // Derived Stats (now using PlayerProgressManager)
  double get maxHealth =>
      baseHealth * PlayerProgressManager.getSpiritMultiplier();
  double get movementSpeed =>
      baseSpeed * (1.0 + (PlayerProgressManager.getSpiritLevel() * 0.01));
  double get attackSpeed =>
      baseAttackSpeed * PlayerProgressManager.getSpiritLevel();
  double get defense =>
      baseDefense * PlayerProgressManager.getSpiritMultiplier();
  double get damage => baseDamage * PlayerProgressManager.getSpiritMultiplier();
  double get critChance =>
      baseCritChance + PlayerProgressManager.getSpiritLevel();
  double get critMultiplier =>
      baseCritMultiplier +
      ((PlayerProgressManager.getSpiritMultiplier() - 1) * 0.5);
  double get pickupRange => 100.0 * PlayerProgressManager.getSpiritMultiplier();

  // Current Health (tracks real-time health)
  double currentHealth = 100.0;

  // UI & Game Elements
  HealthBar? healthBar;
  Vector2 _joystickDelta = Vector2.zero();
  Vector2 movementDirection = Vector2.zero(); // Stores movement direction
  late WhisperWarrior whisperWarrior;
  BaseEnemy? closestEnemy;
  List<Ability> abilities = [];
  final ValueNotifier<List<Ability>> abilityNotifier =
      ValueNotifier([]); // Tracks ability updates
  final List<String> selectedAbilities;
  late final ValueNotifier<List<InventoryItem>> equippedItemsNotifier;
  List<InventoryItem> equippedItems = [];

  bool projectilesShouldPierce = false; // ✅ Track if projectiles should pierce

  bool isDead = false;

  // Special Player Stats
  double vampiricHealing = 0;
  double blackHoleCooldown = 10;
  double timeSinceLastShot = 1.0;
  double lastExplosionTime = 0.0;
  double explosionCooldown = 0.2;

  // Inventory System
  List<Item> inventory =
      []; // Start with an empty inventory// Stores collected items
  ValueNotifier<List<Item>> inventoryNotifier = ValueNotifier([]);
  List<String> unlockedAbilities = [];

  bool hasUmbralFang = false;
  bool hasVeilOfForgotten = false;
  bool hasShardOfUmbrathos = false;

  // Track active effects
  final Set<String> _activeEffects = {};

  // Effect management methods
  bool hasEffect(String effectName) {
    return _activeEffects.contains(effectName);
  }

  void addEffect(String effectName) {
    _activeEffects.add(effectName);
    print('➕ Added effect: $effectName');
  }

  void removeEffect(String effectName) {
    _activeEffects.remove(effectName);
    print('➖ Removed effect: $effectName');
  }

  // Check if the player has a specific item by name
  bool hasItem(String itemName) {
    return inventory.any((item) => item.name == itemName);
  }

  // Add near the top with other flags
  bool canShoot = true; // New flag to control shooting

  // Constructor for Player
  Player({
    required List<String> selectedAbilities,
    List<InventoryItem>? equippedItems,
  })  : selectedAbilities = selectedAbilities,
        super(size: Vector2(128, 128)) {
    print("🛡 Player Constructor - Selected Abilities: $selectedAbilities");

    add(RectangleHitbox(
      size: Vector2(32, 32),
      anchor: Anchor.center,
    ));

    // Initialize abilities based on selected abilities
    for (var abilityName in selectedAbilities) {
      Ability? ability = AbilityFactory.createAbility(abilityName);
      if (ability != null) {
        abilities.add(ability);
      }
    }
    abilityNotifier.value = List.from(abilities);

    // ✅ Fixed: Access the item property of InventoryItem
    inventory.addAll(equippedItems?.map((invItem) => invItem.item) ?? []);

    // ✅ Apply equipped item effects
    Future.delayed(Duration(milliseconds: 100), () {
      applyEquippedItems();
    });

    // Initialize equipped items notifier
    this.equippedItems = equippedItems ?? [];
    equippedItemsNotifier =
        ValueNotifier<List<InventoryItem>>(this.equippedItems);
  }
  get attackModifiers => null;

  @override
  Future<void> onLoad() async {
    try {
      print('🎮 Starting player initialization...');

      // Initialize base component
      await super.onLoad();
      loadInventory();

      // Initialize health bar first
      healthBar = HealthBar(this);
      await gameRef.add(healthBar!);
      print('❤️ Health bar initialized');

      // Initialize WhisperWarrior sprite - KEY DIFFERENCE HERE
      whisperWarrior = WhisperWarrior()
        ..size = size.clone()
        ..anchor = Anchor.center
        ..position = position.clone();
      await gameRef.add(whisperWarrior); // Add to gameRef instead of player
      print('👤 WhisperWarrior added to game');

      // Load unlocked abilities
      unlockedAbilities = PlayerProgressManager.getUnlockedAbilities();
      for (var abilityName in unlockedAbilities) {
        Ability? ability = AbilityFactory.createAbility(abilityName);
        if (ability != null) {
          addAbility(ability);
        }
      }
      print("�� Player Loaded with Abilities: $unlockedAbilities");

      // Apply equipped items
      for (var item in equippedItems) {
        item.applyEffect(this);
        print("🎭 Applied ${item.name} to Player");
      }

      // Reset stats to defaults
      speed = DEFAULT_SPEED;
      baseDamage = DEFAULT_DAMAGE;
      attackCooldown = DEFAULT_ATTACK_COOLDOWN;
      print("🔄 Reset player stats to defaults:");
      print("   Speed: $speed");
      print("   Damage: $baseDamage");
      print("   Attack Speed: ${1 / attackCooldown} shots/sec");

      print('✅ Player initialization complete');
      print('   Position: $position');
      print('   Size: $size');
      print('   Health: $currentHealth/$maxHealth');
    } catch (e, stackTrace) {
      print('❌ Error in player initialization: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ✅ Ensure previously equipped items aren't lost
  void loadInventory() {
    if (inventory.isEmpty) {
      inventory.addAll(equippedItems.map((invItem) => invItem.item));
    }
  }

  Future<void> equipItem(String itemName) async {
    try {
      List<InventoryItem> inventory = await InventoryManager.getInventory();
      List<InventoryItem> matchedItems = inventory
          .where((inventoryItem) => inventoryItem.item.name == itemName)
          .toList();

      if (matchedItems.isNotEmpty) {
        matchedItems.first.applyEffect(this);
        if (!equippedItems.contains(matchedItems.first)) {
          equippedItems.add(matchedItems.first);
          equippedItemsNotifier.value = List.from(equippedItems);
        }
        print("🎭 Equipped: ${matchedItems.first.name}");
      } else {
        print("⚠️ No equipped item found for $itemName");
      }

      print("🔹 Player Stats After Equipping: ");
      printStats();
    } catch (e) {
      print("❌ Error equipping item: $e");
    }
  }

  // Remove an item and update UI
  void removeItem(Item item) {
    if (equippedItems.contains(item)) {
      equippedItems.remove(item);
      item.removeEffect(this);
      equippedItemsNotifier.value = List.from(equippedItems); // ✅ Update UI
      print("🚫 Unequipped: ${item.name}");
    }
  }

  // Collect an item (adds to inventory and saves to JSON storage)
  Future<void> collectItem(Item item) async {
    try {
      // Check if player already has this item
      if (inventory.any((existingItem) => existingItem.name == item.name)) {
        // If duplicate, just give experience
        gainSpiritExp(item.expValue.toDouble());
        print(
            "🌟 Converted duplicate ${item.name} to ${item.expValue} experience");
        return;
      }

      // Add to inventory
      inventory.add(item);
      print("📦 Collected: ${item.name}");

      // Create inventory item
      final inventoryItem = InventoryItem(
        item: item,
        quantity: 1,
        isEquipped: equippedItems.length < 5, // Auto-equip if less than 5 items
        isNew: true,
      );

      // If we have space and it's a new item, equip it
      if (equippedItems.length < 5) {
        equippedItems.add(inventoryItem);
        equippedItemsNotifier.value = List.from(equippedItems);
        print("🎭 Auto-equipped: ${item.name}");
      }

      // Save to storage
      final currentInventory = await InventoryStorage.loadInventory();
      currentInventory.add(inventoryItem);
      await InventoryStorage.saveInventory(currentInventory);
      print("💾 Saved ${item.name} to inventory storage");
    } catch (e) {
      print("❌ Error collecting item: $e");
    }
  }

  // Equipment handling
  Future<void> applyEquippedItems() async {
    print('🎮 Applying equipped items to player');

    try {
      // Get equipped items from inventory manager
      List<InventoryItem> equippedItems =
          await InventoryManager.getEquippedItems();

      // Apply effects for each equipped item
      for (var item in equippedItems) {
        try {
          item.applyEffect(this);
          print('✅ Applied ${item.name}');
        } catch (e) {
          print('⚠️ Error applying item ${item.name}: $e');
        }
      }
    } catch (e) {
      print('❌ Error loading equipped items: $e');
    }
  }

  // Apply inventory item effects to player stats
  void applyInventoryItemEffect(InventoryItem item) {
    item.stats.forEach((stat, value) {
      if (stat == "Attack Speed") baseAttackSpeed *= (1 + value);
      if (stat == "Defense Bonus" && currentHealth < maxHealth * 0.5)
        baseDefense *= (1 + value);
      if (stat == "Spirit Multiplier") {
        PlayerProgressManager.setSpiritItemBonus(value);
      }
    });
  }

  // Remove inventory item effects from player stats
  void removeInventoryItemEffect(InventoryItem item) {
    item.stats.forEach((stat, value) {
      if (stat == "Attack Speed") baseAttackSpeed /= (1 + value);
      if (stat == "Defense Bonus") baseDefense /= (1 + value);
      if (stat == "Spirit Multiplier") {
        PlayerProgressManager.setSpiritItemBonus(0.0);
      }
    });
  }

  // Update joystick input for movement
  void updateJoystick(Vector2 delta) {
    _joystickDelta = delta;
  }

  // Movement methods
  void moveUp() => _joystickDelta = Vector2(0, -1);
  void moveDown() => _joystickDelta = Vector2(0, 1);
  void moveLeft() => _joystickDelta = Vector2(-1, 0);
  void moveRight() => _joystickDelta = Vector2(1, 0);
  void stopMovement() =>
      _joystickDelta = Vector2.zero(); // Stops movement when key is released

  @override
  void update(double dt) {
    super.update(dt);

    if (!isDead) {
      updateClosestEnemy(); // ✅ Ensure enemies are tracked each frame
      updateMovement(dt);
    }
  }

  void updateMovement(double dt) {
    if (!isMounted || isDead) {
      return; // Don't do anything if dead or unmounted
    }

    Vector2 totalMovement = movementDirection + _joystickDelta;
    if (totalMovement.length > 0) {
      Vector2 prevPosition = position.clone();
      position = prevPosition +
          (totalMovement.normalized() * movementSpeed * dt) * 0.75;
      whisperWarrior.scale.x = totalMovement.x > 0 ? -1 : 1;
      whisperWarrior.playAnimation('attack');
    } else {
      whisperWarrior.playAnimation('idle');
    }

    whisperWarrior.position = position.clone();

    // Update health bar position
    if (healthBar != null) {
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }

    // Only update abilities and shooting if not dead
    if (!isDead) {
      // Update abilities
      for (var ability in abilities) {
        ability.onUpdate(this, dt);
      }

      // Handle shooting - Add canShoot check
      if (canShoot) {
        // Add this check
        timeSinceLastShot += dt;
        if (timeSinceLastShot >= (1 / attackSpeed) && closestEnemy != null) {
          final projectile = Projectile.shootFromPlayer(
            player: this,
            targetPosition: closestEnemy!.position,
            projectileSpeed: 500,
            damage: damage.toDouble(),
            onHit: (enemy) {
              // Handle any specific on-hit effects if needed
            },
          );
          gameRef.add(projectile);
          timeSinceLastShot = 0.0;
        }
      }
    }
  }

  // Gain experience (now delegates to PlayerProgressManager)
  void gainSpiritExp(double amount) {
    PlayerProgressManager.gainSpiritExp(amount);
  }

  // Take damage and handle death
  void takeDamage(double amount) {
    if (currentHealth <= 0) return; // Prevent damage when dead

    currentHealth -= amount;
    print('💥 Player took $amount damage. Health: $currentHealth/$maxHealth');

    // Trigger hit animation if available
    if (whisperWarrior != null) {
      whisperWarrior.playAnimation('hit');
    }

    // Check for death
    if (currentHealth <= 0 && !isDead) {
      isDead = true;
      whisperWarrior.playAnimation('death');

      // Get animation duration correctly
      final double animationDuration = whisperWarrior.animation!.frames.length *
          whisperWarrior.animation!.frames.first.stepTime;

      Future.delayed(Duration(milliseconds: (animationDuration * 100).toInt()),
          () {
        whisperWarrior.playAnimation('death');
        removeFromParent();
        healthBar?.removeFromParent();
      });

      Future.delayed(Duration(seconds: 2), () {
        gameRef.overlays.add('retryOverlay');
      });

      final fireAura =
          gameRef.children.whereType<WhisperingFlames>().firstOrNull;
      if (fireAura != null) {
        fireAura.removeFromParent();
      }

      onDeath();
    } else {
      healthBar?.updateHealth(currentHealth.toInt(), maxHealth.toInt());
    }
  }

  Future<void> onDeath() async {
    print('💀 Player died');
    if (whisperWarrior != null) {
      whisperWarrior.playAnimation('death');

      final double animationDuration = whisperWarrior.animation!.frames.length *
          whisperWarrior.animation!.frames.first.stepTime;

      Future.delayed(Duration(milliseconds: (animationDuration * 1000).toInt()),
          () {
        removeFromParent();
      });

      Future.delayed(Duration(seconds: 2), () {
        gameRef.overlays.add('retryOverlay');
      });

      // Handle music using AudioManager
      final audioManager = AudioManager();
      await audioManager.stopBackgroundMusic();
      print('🔊 Stopped background music');
      await audioManager.playGameOverMusic();
      print('🔊 Playing game over music');
    }
  }

  // Shoot a projectile at the t

  // Add an item to the inventory
  void addItem(Item item) {
    inventory.add(item);
    inventoryNotifier.value = List.from(inventory); // Triggers UI update
    print("📦 Added ${item.name} to inventory.");
  }

  // Update applySelectedAbilities to handle duplicates better
  void applySelectedAbilities() {
    List<String> unlockedAbilities =
        PlayerProgressManager.getUnlockedAbilities();

    for (var abilityName in selectedAbilities) {
      if (unlockedAbilities.contains(abilityName) &&
          !abilities.any((a) => a.name == abilityName)) {
        Ability? ability = AbilityFactory.createAbility(abilityName);
        if (ability != null) {
          addAbility(ability);
        }
      }
    }
  }

  // Update addAbility to be more robust
  void addAbility(Ability ability) {
    if (!selectedAbilities.contains(ability.name)) {
      print(
          "⚠️ Ability ${ability.name} not in selected abilities, skipping...");
      return;
    }

    if (abilities.any((a) => a.name == ability.name)) {
      print("⚠️ Ability ${ability.name} already exists, skipping...");
      return;
    }

    abilities.add(ability);
    abilityNotifier.value = List.from(abilities);
    ability.applyEffect(this);
    print("🔥 Added Ability: ${ability.name}");
  }

  // Check if the player has a specific ability
  bool hasAbility<T extends Ability>() {
    return abilities.any((ability) => ability is T);
  }

  // Find the closest enemy
  BaseEnemy? findClosestEnemy() {
    double closestDistance = double.infinity;
    BaseEnemy? closest;

    for (final enemy in gameRef.children.whereType<BaseEnemy>()) {
      final distance = (enemy.position - position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = enemy;
      }
    }

    return closest;
  }

  // Update the closest enemy
  void updateClosestEnemy() {
    double closestDistance = double.infinity;
    BaseEnemy? newClosestEnemy;

    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      // Skip non-targetable enemies
      if (!enemy.isTargetable) continue;

      double distance = enemy.position.distanceTo(position);
      if (distance < closestDistance) {
        closestDistance = distance;
        newClosestEnemy = enemy;
      }
    }

    closestEnemy = newClosestEnemy;
  }

  // Gain health and display healing numbers
  void gainHealth(int amount) {
    if (currentHealth < maxHealth && amount > 0) {
      int healedAmount = ((currentHealth + amount) > maxHealth)
          ? (maxHealth - currentHealth).toInt()
          : amount; // Explicit cast
      currentHealth += healedAmount;

      if (healedAmount > 0) {
        final healingNumber = HealingNumber(healedAmount, position.clone());
        gameRef.add(healingNumber);
      }
    }
  }

  // Trigger an explosion at a specific position
  void triggerExplosion(Vector2 position) {
    double currentTime = gameRef.currentTime();

    // Prevent excessive explosions
    if (currentTime - lastExplosionTime < explosionCooldown) {
      return;
    }

    lastExplosionTime = currentTime; // Update cooldown

    gameRef.add(Explosion(position));

    // Calculate explosion damage based on Spirit Level
    double explosionDamage = damage * 0.25; // Base: 25% of player damage
    explosionDamage *=
        PlayerProgressManager.getSpiritMultiplier(); // Scale with Spirit Level

    // Apply damage to nearby enemies
    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;

      if (distance < 100.0) {
        // Explosion radius
        double finalDamage = explosionDamage.clamp(1, 9999);
        enemy.takeDamage(finalDamage);
      }
    }
  }

  @override
  void onRemove() {
    abilityNotifier.dispose();

    final fireAura = gameRef.children.whereType<WhisperingFlames>().firstOrNull;
    if (fireAura != null) {
      fireAura.removeFromParent();
    }

    super.onRemove();
  }

  // Add a passive effect to the player
  void addPassiveEffect(PassiveEffect passiveEffect) {}

  // Remove a passive effect from the player
  void removePassiveEffect(String s) {}

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
  }

  void clearAbilities() {
    abilities.clear();
  }

  List<Ability> getAbilities() {
    return abilities;
  }

  Ability? getAbilityByName(String name) {
    try {
      return abilities.firstWhere(
        (ability) => ability.name == name,
      );
    } catch (e) {
      // Return BasicAttack for basic attacks, null otherwise
      return name == 'Basic Attack' ? BasicAttack() : null;
    }
  }

  // Getters
  double getMaxHealth() => maxHealth;
  double getHealth() => currentHealth;
  double getMoveSpeed() => movementSpeed;
  double getDamageMultiplier() => damage;

  // Setters
  void setMaxHealth(double value) {
    baseHealth = value;
    print('🛡️ Max Health updated to: $baseHealth');
  }

  void setHealth(double value) {
    currentHealth = value.clamp(0, maxHealth);
    print('❤️ Health updated to: $currentHealth');
  }

  void setMoveSpeed(double value) {
    baseSpeed = value.clamp(100, 400); // Prevent too slow/fast movement
    print('👟 Move Speed updated to: $baseSpeed');
  }

  void setDamageMultiplier(double value) {
    baseDamage = value.clamp(0.5, 3.0); // Prevent extreme damage values
    print('⚔️ Damage Multiplier updated to: $baseDamage');
  }

  // Debug info
  void printStats() {
    print('\n📊 Player Stats:');
    print('Health: $currentHealth/$maxHealth');
    print('Move Speed: $movementSpeed');
    print('Damage Multiplier: $damage\n');
  }

  void heal(double amount) {
    setHealth(currentHealth + amount);
    print('💚 Player healed $amount. Health: $currentHealth/$maxHealth');
  }

  // Add these getters
  int get level => PlayerProgressManager.getLevel();
  int get xp => PlayerProgressManager.getXp();
  double get health => currentHealth;

  // Method to determine if an attack is critical
  bool isCriticalHit() {
    final randomValue = gameRef.random.nextDouble() * 100;
    return randomValue < critChance;
  }

  // Add these methods to Player class
  void disableShooting() {
    canShoot = false;
    print('🚫 Player shooting disabled');
  }

  void enableShooting() {
    canShoot = true;
    print('✅ Player shooting enabled');
  }
}

// Update WhisperWarrior class to ensure sprite loading

class PlayerStatsOverlay extends StatelessWidget {
  final Player player;
  final RogueShooterGame game;

  const PlayerStatsOverlay({Key? key, required this.player, required this.game})
      : super(key: key);

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
              'Player Stats',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatText('Max Health', player.maxHealth),
            _buildStatText('Current Health', player.currentHealth),
            _buildStatText('Movement Speed', player.movementSpeed),
            _buildStatText('Attack Speed', player.attackSpeed),
            _buildStatText('Defense', player.defense),
            _buildStatText('Damage', player.damage),
            _buildStatText('Crit Chance', player.critChance),
            _buildStatText('Crit Multiplier', player.critMultiplier),
            _buildStatText('Pickup Range', player.pickupRange),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                print("Attempting to close Player Stats");
                game.resumeEngine(); // Resume the game engine
                print("Resumed game engine");
                game.overlays
                    .remove('playerStatsOverlay'); // Remove the overlay
                print("Removed playerStatsOverlay");
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

  Widget _buildStatText(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
