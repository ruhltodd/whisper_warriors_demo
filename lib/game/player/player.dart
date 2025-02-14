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

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final DamageTracker damageTracker =
      DamageTracker('player'); // Add ability name

  // Base Stats (before Spirit Level modifications)
  double baseHealth = 100.0;
  double baseSpeed = 100.0;
  double baseAttackSpeed = 1.0; // Attacks per second
  double baseDefense = 0.0; // % Damage reduction
  double baseDamage = 10.0;
  double baseCritChance = 5.0; // % Chance
  double baseCritMultiplier = 1.5; // 1.5x damage on crit

  // Spirit Level System
  double spiritMultiplier = 5.0; // Scales with Spirit Level
  int spiritLevel = 1;
  double spiritExp = 0.0;
  double spiritExpToNextLevel = 500.0;

  // Derived Stats (calculated from Spirit Level)
  double get maxHealth => baseHealth * spiritMultiplier;
  double get movementSpeed => baseSpeed * spiritMultiplier;
  double get attackSpeed => baseAttackSpeed * (1 + (spiritMultiplier - 1));
  double get defense => baseDefense * spiritMultiplier;
  double get damage => baseDamage * spiritMultiplier;
  double get critChance => baseCritChance * spiritMultiplier;
  double get critMultiplier =>
      baseCritMultiplier + ((spiritMultiplier - 1) * 0.5);
  double get pickupRange =>
      100.0 *
      spiritMultiplier; // Base range of 100, scales with spirit multiplier

  // Current Health (tracks real-time health)
  double currentHealth = 100.0;

  // UI & Game Elements
  HealthBar? healthBar;
  Vector2 _joystickDelta = Vector2.zero();
  double speed = 140; // Adjust this value to control player movement speed
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
  double firingCooldown = 1.0;
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

  // Check if the player has a specific item by name
  bool hasItem(String itemName) {
    return inventory.any((item) => item.name == itemName);
  }

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
      print("🔥 Player Loaded with Abilities: $unlockedAbilities");

      // Apply equipped items
      for (var item in equippedItems) {
        item.applyEffect(this);
        print("🎭 Applied ${item.name} to Player");
      }

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
      if (stat == "Spirit Multiplier") spiritMultiplier *= (1 + value);
    });
  }

  // Remove inventory item effects from player stats
  void removeInventoryItemEffect(InventoryItem item) {
    item.stats.forEach((stat, value) {
      if (stat == "Attack Speed") baseAttackSpeed /= (1 + value);
      if (stat == "Defense Bonus") baseDefense /= (1 + value);
      if (stat == "Spirit Multiplier") spiritMultiplier /= (1 + value);
    });
  }

  // Update spirit multiplier based on spirit level and equipped items
  void updateSpiritMultiplier() {
    spiritMultiplier = 1.0 + (spiritLevel * 0.05);

    // Apply "Shard of Umbrathos" bonus if equipped
    if (equippedItems.any((item) => item is ShardOfUmbrathos)) {
      spiritMultiplier *= 1.15; // 15% Bonus to Spirit Multiplier
    }
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

    updateSpiritMultiplier();
    updateClosestEnemy();

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

    // Update abilities
    for (var ability in abilities) {
      ability.onUpdate(this, dt);
    }

    // Handle shooting
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

  // Gain spirit experience and handle level-ups
  void gainSpiritExp(double amount) {
    while (amount > 0) {
      double remainingToLevel = spiritExpToNextLevel - spiritExp;

      if (amount >= remainingToLevel) {
        spiritExp = spiritExpToNextLevel;
        amount -= remainingToLevel;
        spiritLevelUp(); // Level up before adding more XP
      } else {
        spiritExp += amount;
        amount = 0;
      }
    }

    // Update experience bar
    gameRef.experienceBar
        .updateSpirit(spiritExp, spiritExpToNextLevel, spiritLevel);
  }

  // Handle spirit level up
  void spiritLevelUp() {
    spiritLevel++;
    spiritExp -= spiritExpToNextLevel;
    spiritExpToNextLevel *= 1.2;
    updateSpiritMultiplier();
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

      // Get animation duration correctly
      final double animationDuration = whisperWarrior.animation!.frames.length *
          whisperWarrior.animation!.frames.first.stepTime;

      Future.delayed(Duration(milliseconds: (animationDuration * 1000).toInt()),
          () {
        removeFromParent();
      });

      // Show retry overlay after a delay
      Future.delayed(Duration(seconds: 2), () {
        gameRef.overlays.add('retryOverlay');
      });

      // Handle music
      await gameRef.stopBackgroundMusic();
      await gameRef.playGameOverMusic();
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
    final enemies = gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) {
      closestEnemy = null;
      return;
    }

    BaseEnemy? newClosest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
      final distance = (enemy.position - position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        newClosest = enemy;
      }
    }

    if (newClosest != closestEnemy) {
      closestEnemy = newClosest;
    }
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
    explosionDamage *= spiritMultiplier; // Scale with Spirit Level

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

  void updateMovement(double dt) {
    if (!isMounted) return;

    updateSpiritMultiplier();
    updateClosestEnemy();

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

    // Update abilities
    for (var ability in abilities) {
      ability.onUpdate(this, dt);
    }

    // Handle shooting
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

// Update WhisperWarrior class to ensure sprite loading
