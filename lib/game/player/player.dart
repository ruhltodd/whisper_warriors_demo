import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
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
import 'package:whisper_warriors/game/effects/fireaura.dart';

class Player extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  // Base Stats (before Spirit Level modifications)
  double baseHealth = 100.0;
  double baseSpeed = 140.0;
  double baseAttackSpeed = 1.0; // Attacks per second
  double baseDefense = 0.0; // % Damage reduction
  double baseDamage = 10.0;
  double baseCritChance = 5.0; // % Chance
  double baseCritMultiplier = 1.5; // 1.5x damage on crit

  // Spirit Level System
  double spiritMultiplier = 1.0; // Scales with Spirit Level
  int spiritLevel = 1;
  double spiritExp = 0.0;
  double spiritExpToNextLevel = 1000.0;

  // Derived Stats (calculated from Spirit Level)
  double get maxHealth => baseHealth * spiritMultiplier;
  double get movementSpeed => baseSpeed * spiritMultiplier;
  double get attackSpeed => baseAttackSpeed * (1 + (spiritMultiplier - 1));
  double get defense => baseDefense * spiritMultiplier;
  double get damage => baseDamage * spiritMultiplier;
  double get critChance => baseCritChance * spiritMultiplier;
  double get critMultiplier =>
      baseCritMultiplier + ((spiritMultiplier - 1) * 0.5);

  // Current Health (tracks real-time health)
  double currentHealth = 100.0;

  // UI & Game Elements
  HealthBar? healthBar;
  Vector2 joystickDelta = Vector2.zero();
  Vector2 movementDirection = Vector2.zero(); // Stores movement direction
  late WhisperWarrior whisperWarrior;
  BaseEnemy? closestEnemy;
  List<Ability> abilities = [];
  final ValueNotifier<List<Ability>> abilityNotifier =
      ValueNotifier([]); // Tracks ability updates
  final List<String> selectedAbilities; // Store selected abilities
  final ValueNotifier<List<InventoryItem>> equippedItemsNotifier =
      ValueNotifier([]); // Live-updating notifier
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
  List<Item> inventory = [
    UmbralFang(),
    VeilOfTheForgotten(),
    ShardOfUmbrathos()
  ]; // Stores collected items
  List<InventoryItem> equippedItems; // Store equipped items
  ValueNotifier<List<Item>> inventoryNotifier = ValueNotifier([]);

  bool hasUmbralFang = false;
  bool hasVeilOfForgotten = false;
  bool hasShardOfUmbrathos = false;

  // Check if the player has a specific item by name
  bool hasItem(String itemName) {
    return inventory.any((item) => item.name == itemName);
  }

  // Apply selected abilities to the player
  void applySelectedAbilities() {
    for (var ability in selectedAbilities) {
      addAbility(AbilityFactory.createAbility(ability)!);
    }
  }

  // Constructor
  Player({required this.selectedAbilities, required this.equippedItems})
      : super(size: Vector2(128, 128)) {
    add(CircleHitbox.relative(
      0.5, // 50% of player size (adjust as needed)
      parentSize: size,
    ));

    // Apply equipped items on initialization
    applyEquippedItems();
  }

  get attackModifiers => null;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    healthBar = HealthBar(this);
    gameRef.add(healthBar!);

    whisperWarrior = WhisperWarrior()
      ..size = size.clone()
      ..anchor = Anchor.center
      ..position = position.clone();
    gameRef.add(whisperWarrior);

    // Apply effects of pre-added items
    for (var item in inventory) {
      InventoryItem invItem = InventoryItem(item: item, isEquipped: true);
      InventoryManager.addItem(invItem);
      equipItem(item.name);
    }
  }

  // Equip an item and update UI
  void equipItem(String itemName) {
    List<InventoryItem> matchedItems = InventoryManager.getInventory()
        .where((inventoryItem) => inventoryItem.item.name == itemName)
        .toList();

    if (matchedItems.isNotEmpty) {
      matchedItems.first.applyEffect(this);
      if (!equippedItems.contains(matchedItems.first)) {
        equippedItems.add(matchedItems.first);
        equippedItemsNotifier.value = List.from(equippedItems); // Notify UI
      }
      print("🎭 Equipped: ${matchedItems.first.item.name}");
    } else {
      print("⚠️ No equipped item found for $itemName");
    }

    // Debug logs
    print("🔹 Player Stats After Equipping: ");
    print(" - Attack Speed: $attackSpeed");
    print(" - Defense: $defense");
    print(" - Spirit Multiplier: $spiritMultiplier");
  }

  // Remove an item and update UI
  void removeItem(Item item) {
    if (equippedItems.contains(item)) {
      equippedItems.remove(item);
      item.removeEffect(this);
      print("🚫 Unequipped: ${item.name}");
    }
  }

  // Collect an item (adds to inventory but doesn't equip)
  void collectItem(Item item) {
    if (!inventory.contains(item)) {
      inventory.add(item);
      print("📦 Collected: ${item.name}");
    }
  }

  // Apply effects of equipped items
  void applyEquippedItems() {
    hasUmbralFang =
        equippedItems.any((invItem) => invItem.item.name == "Umbral Fang");
    hasVeilOfForgotten = equippedItems
        .any((invItem) => invItem.item.name == "Veil of the Forgotten");
    hasShardOfUmbrathos = equippedItems
        .any((invItem) => invItem.item.name == "Shard of Umbrathos");
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
    joystickDelta = delta;
  }

  // Movement methods
  void moveUp() => joystickDelta = Vector2(0, -1);
  void moveDown() => joystickDelta = Vector2(0, 1);
  void moveLeft() => joystickDelta = Vector2(-1, 0);
  void moveRight() => joystickDelta = Vector2(1, 0);
  void stopMovement() =>
      joystickDelta = Vector2.zero(); // Stops movement when key is released

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastShot += dt; // Ensure cooldown timer increases

    updateSpiritMultiplier();
    updateClosestEnemy(); // Update the closest enemy

    Vector2 totalMovement = movementDirection + joystickDelta;
    if (totalMovement.length > 0) {
      Vector2 prevPosition = position.clone(); // Store previous position

      // Apply linear interpolation for smoother movement
      position = prevPosition +
          (totalMovement.normalized() * movementSpeed * dt) * 0.75;

      whisperWarrior.scale.x = totalMovement.x > 0 ? -1 : 1;
      whisperWarrior.playAnimation('attack');
    } else {
      whisperWarrior.playAnimation('idle');
    }

    // Ensure sprite updates smoothly with movement
    whisperWarrior.position = position.clone();

    // Shoot projectile if cooldown is over and an enemy is targeted
    if (timeSinceLastShot >= (1 / attackSpeed) && closestEnemy != null) {
      print("🛑 Projectile removed: Max range exceeded");
      shootProjectile(damage.toInt(), closestEnemy!); // Pass required arguments
      timeSinceLastShot = 0.0; // Reset cooldown
    }

    // Update health bar position
    if (healthBar != null) {
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }

    // Update abilities
    for (var ability in abilities) {
      ability.onUpdate(this, dt);
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
    print("✨ Spirit Level Up! New Spirit Level: $spiritLevel");
  }

  // Take damage and handle death
  void takeDamage(int damage) async {
    if (isDead) return; // Prevent extra damage when player dies

    double reducedDamage = damage * (1 - (defense / 100));

    // Apply Veil of the Forgotten effect if HP < 50%
    if (equippedItems.any((item) => item is VeilOfTheForgotten) &&
        currentHealth < maxHealth * 0.5) {
      reducedDamage *= 0.8; // Reduce damage by 20%
      print("🌀 Veil of the Forgotten active! Damage reduced.");
    }

    currentHealth -= reducedDamage.clamp(1, maxHealth).toInt(); // Explicit cast

    // Lose Spirit EXP instead of instantly dropping a level
    double expLoss =
        spiritExpToNextLevel * 0.05; // Lose 5% of current level EXP
    spiritExp -= expLoss;
    if (spiritExp < 0) spiritExp = 0; // Prevent negative EXP

    gameRef.experienceBar
        .updateSpirit(spiritExp, spiritExpToNextLevel, spiritLevel);
    whisperWarrior.playAnimation('hit');

    if (currentHealth <= 0 && !isDead) {
      isDead = true;
      whisperWarrior.playAnimation('death');

      // Get animation duration correctly
      final double animationDuration = whisperWarrior.animation!.frames.length *
          whisperWarrior.animation!.frames.first.stepTime;

      print("☠️ Death animation will play for ${animationDuration}s");

      Future.delayed(Duration(milliseconds: (animationDuration * 100).toInt()),
          () {
        print("☠️ Player death animation complete, now removing...");
        whisperWarrior.playAnimation('death');
        removeFromParent();
        healthBar?.removeFromParent();
      });

      Future.delayed(Duration(seconds: 2), () {
        gameRef.overlays.add('retryOverlay');
      });

      final fireAura = gameRef.children.whereType<FireAura>().firstOrNull;
      if (fireAura != null) {
        print("🔥 Removing FireAura because player is dead.");
        fireAura.removeFromParent();
      }

      await gameRef.stopBackgroundMusic();
      await gameRef.playGameOverMusic();
    } else {
      healthBar?.updateHealth(currentHealth.toInt(), maxHealth.toInt());
    }
  }

  // Shoot a projectile at the target
  void shootProjectile(int damage, PositionComponent target,
      {bool isCritical = false}) {
    // ✅ Ensure there's a valid enemy target before firing
    BaseEnemy? target = findClosestEnemy();
    if (target == null) {
      print("⚠️ No valid enemy target found - projectile not fired!");
      return;
    }

    print("🚀 shootProjectile() called!");

    final Vector2 direction = (target.position - position).normalized();

    final projectile = Projectile(
      damage: damage,
      velocity: direction * 500, // Adjust projectile speed
      maxRange: 1600, // Player projectiles should have a range
      player: this,
      onHit: (enemy) {
        // ✅ Apply Cursed Echo only **once** per attack
      },
    )
      ..position = position.clone()
      ..size = Vector2(50, 50)
      ..anchor = Anchor.center;

    gameRef.add(projectile);
    print("🎯 PLAYER PROJECTILE FIRED towards ${target.position}");
    // ✅ **Trigger Cursed Echo per shot, not per enemy hit**
    if (hasAbility<CursedEcho>() && gameRef.random.nextDouble() < 0.2) {
      Future.delayed(Duration(milliseconds: 100), () {
        print("🔁 Cursed Echo triggered! Repeating projectile...");
        shootProjectile(damage, closestEnemy!,
            isCritical: isCritical); // Fire again
      });
    }
  }

  // Add an item to the inventory
  void addItem(Item item) {
    inventory.add(item);
    inventoryNotifier.value = List.from(inventory); // Triggers UI update
    print("📦 Added ${item.name} to inventory.");
  }

  // Add an ability to the player
  void addAbility(Ability ability) {
    abilities.add(ability);
    abilityNotifier.value = List.from(abilities);
    ability.applyEffect(this);
  }

  // Check if the player has a specific ability
  bool hasAbility<T extends Ability>() {
    return abilities.any((ability) => ability is T);
  }

  // Find the closest enemy
  BaseEnemy? findClosestEnemy() {
    final enemies = gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) {
      return null;
    }

    BaseEnemy? closest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
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
      print("No enemies found.");
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
      print("🎯 New closest enemy assigned at ${closestEnemy?.position}");
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
    print("💥 Explosion triggered at $position");

    // Calculate explosion damage based on Spirit Level
    double explosionDamage = damage * 0.25; // Base: 25% of player damage
    explosionDamage *= spiritMultiplier; // Scale with Spirit Level

    // Apply damage to nearby enemies
    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;

      if (distance < 100.0) {
        // Explosion radius
        int finalDamage = explosionDamage.toInt().clamp(1, 9999);
        enemy.takeDamage(finalDamage);
        print("🔥 Explosion hit enemy for $finalDamage damage!");
      }
    }
  }

  @override
  void onRemove() {
    abilityNotifier.dispose();
    super.onRemove();
  }

  // Add a passive effect to the player
  void addPassiveEffect(PassiveEffect passiveEffect) {}

  // Remove a passive effect from the player
  void removePassiveEffect(String s) {}
}
