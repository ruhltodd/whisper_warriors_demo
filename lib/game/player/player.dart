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
  // ✅ Base Stats (before Spirit Level modifications)
  double baseHealth = 100.0;
  double baseSpeed = 140.0;
  double baseAttackSpeed = 1.0; // Attacks per second
  double baseDefense = 0.0; // % Damage reduction
  double baseDamage = 10.0;
  double baseCritChance = 5.0; // % Chance
  double baseCritMultiplier = 1.5; // 1.5x damage on crit

  // ✅ Spirit Level System
  double spiritMultiplier = 1.0; // Scales with Spirit Level
  int spiritLevel = 1;
  double spiritExp = 0.0;
  double spiritExpToNextLevel = 1000.0;

  // ✅ Derived Stats (calculated from Spirit Level)
  double get maxHealth => baseHealth * spiritMultiplier;
  double get movementSpeed => baseSpeed * spiritMultiplier;
  double get attackSpeed => baseAttackSpeed * (1 + (spiritMultiplier - 1));
  double get defense => baseDefense * spiritMultiplier;
  double get damage => baseDamage * spiritMultiplier;
  double get critChance => baseCritChance * spiritMultiplier;
  double get critMultiplier =>
      baseCritMultiplier + ((spiritMultiplier - 1) * 0.5);

  // ✅ Current Health (tracks real-time health)
  double currentHealth = 100.0;

  // ✅ UI & Game Elements
  HealthBar? healthBar;
  Vector2 joystickDelta = Vector2.zero();
  Vector2 movementDirection = Vector2.zero(); // ✅ Stores movement direction
  late WhisperWarrior whisperWarrior;
  BaseEnemy? closestEnemy;
  List<Ability> abilities = [];
  final ValueNotifier<List<Ability>> abilityNotifier =
      ValueNotifier([]); // ✅ Tracks ability updates
  final List<String> selectedAbilities; // ✅ Store selected abilities
  final ValueNotifier<List<InventoryItem>> equippedItemsNotifier =
      ValueNotifier([]); // ✅ Live-updating notifier

  bool isDead = false;

  // ✅ Special Player Stats
  double vampiricHealing = 0;
  double blackHoleCooldown = 10;
  double firingCooldown = 1.0;
  double timeSinceLastShot = 1.0;
  double lastExplosionTime = 0.0;
  double explosionCooldown = 0.2;

  // ✅ Inventory System
  // ✅ Inventory System
  List<Item> inventory = [
    UmbralFang(),
    VeilOfTheForgotten(),
    ShardOfUmbrathos()
  ]; // // 🏹 **Stores collected items**
  List<InventoryItem> equippedItems; // ✅ Store equipped items
  ValueNotifier<List<Item>> inventoryNotifier = ValueNotifier([]);

  bool hasUmbralFang = false;
  bool hasVeilOfForgotten = false;
  bool hasShardOfUmbrathos = false;
  bool hasItem(String itemName) {
    return inventory.any((item) => item.name == itemName); // ✅ Compare names
  }

  void applySelectedAbilities() {
    for (var ability in selectedAbilities) {
      addAbility(AbilityFactory.createAbility(ability)!);
    }
  }

  Player({required this.selectedAbilities, required this.equippedItems})
      : super(size: Vector2(128, 128)) {
    add(CircleHitbox.relative(
      0.5, // 50% of player size (adjust as needed)
      parentSize: size,
    ));

    // Removed applySelectedAbilities() to prevent double application.
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

    // ✅ Apply Effects of Pre-Added Items
    // For each item in the player's local inventory, wrap it as an InventoryItem,
    // add it to the InventoryManager, and equip it once.
    for (var item in inventory) {
      InventoryItem invItem = InventoryItem(item: item, isEquipped: true);
      InventoryManager.addItem(invItem);
      equipItem(item.name);
    }
  }

  // ✅ **Equip an Item & Update UI**
  void equipItem(String itemName) {
    List<InventoryItem> matchedItems = InventoryManager.getInventory()
        .where((inventoryItem) => inventoryItem.item.name == itemName)
        .toList();

    if (matchedItems.isNotEmpty) {
      matchedItems.first.applyEffect(this);
      if (!equippedItems.contains(matchedItems.first)) {
        equippedItems.add(matchedItems.first);
        equippedItemsNotifier.value = List.from(equippedItems); // ✅ Notify UI
      }
      print("🎭 Equipped: ${matchedItems.first.item.name}");
    } else {
      print("⚠️ No equipped item found for $itemName");
    }

    // ✅ **Remove an Item & Update UI**
    void removeItem(Item item) {
      equippedItems.removeWhere((invItem) => invItem.item == item);
      equippedItemsNotifier.value = List.from(equippedItems); // ✅ Notify UI
      print("🚫 Unequipped: ${item.name}");
    }

    // Debug logs
    print("🔹 Player Stats After Equipping: ");
    print(" - Attack Speed: $attackSpeed");
    print(" - Defense: $defense");
    print(" - Spirit Multiplier: $spiritMultiplier");
  }

  // 🎭 **Remove an Item**
  void removeItem(Item item) {
    if (equippedItems.contains(item)) {
      equippedItems.remove(item);
      item.removeEffect(this);
      print("🚫 Unequipped: ${item.name}");
    }
  }

  // 🎒 **Collect an Item (Adds to inventory but doesn't equip)**
  void collectItem(Item item) {
    if (!inventory.contains(item)) {
      inventory.add(item);
      print("📦 Collected: ${item.name}");
    }
  }

  void applyEquippedItems() {
    hasUmbralFang =
        equippedItems.any((invItem) => invItem.item.name == "Umbral Fang");
    hasVeilOfForgotten = equippedItems
        .any((invItem) => invItem.item.name == "Veil of the Forgotten");
    hasShardOfUmbrathos = equippedItems
        .any((invItem) => invItem.item.name == "Shard of Umbrathos");
  }

  void applyInventoryItemEffect(InventoryItem item) {
    item.stats.forEach((stat, value) {
      if (stat == "Attack Speed") baseAttackSpeed *= (1 + value);
      if (stat == "Defense Bonus" && currentHealth < maxHealth * 0.5)
        baseDefense *= (1 + value);
      if (stat == "Spirit Multiplier") spiritMultiplier *= (1 + value);
    });
  }

  void removeInventoryItemEffect(InventoryItem item) {
    item.stats.forEach((stat, value) {
      if (stat == "Attack Speed") baseAttackSpeed /= (1 + value);
      if (stat == "Defense Bonus") baseDefense /= (1 + value);
      if (stat == "Spirit Multiplier") spiritMultiplier /= (1 + value);
    });
  }

  void updateSpiritMultiplier() {
    // ✅ Each Spirit Level increases all stats by 5%
    spiritMultiplier = 1.0 + (spiritLevel * 0.05);

    // 🔹 **Apply "Shard of Umbrathos" bonus if equipped**
    if (equippedItems.any((item) => item is ShardOfUmbrathos)) {
      spiritMultiplier *= 1.15; // ✅ 15% Bonus to Spirit Multiplier
    }
  }

  void updateJoystick(Vector2 delta) {
    joystickDelta = delta;
  }

  void moveUp() {
    joystickDelta = Vector2(0, -1);
  }

  void moveDown() {
    joystickDelta = Vector2(0, 1);
  }

  void moveLeft() {
    joystickDelta = Vector2(-1, 0);
  }

  void moveRight() {
    joystickDelta = Vector2(1, 0);
  }

  void stopMovement() {
    joystickDelta = Vector2.zero(); // ✅ Stops movement when key is released
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastShot += dt; // ✅ Ensure cooldown timer increases

    updateSpiritMultiplier();
    updateClosestEnemy(); // 🔥 This ensures `closestEnemy` is updated

    Vector2 totalMovement = movementDirection + joystickDelta;
    if (totalMovement.length > 0) {
      Vector2 prevPosition = position.clone(); // ✅ Store previous position

      // 🔹 **Manually apply linear interpolation for smoother movement**
      position = prevPosition +
          (totalMovement.normalized() * movementSpeed * dt) * 0.75;

      whisperWarrior.scale.x = totalMovement.x > 0 ? -1 : 1;
      whisperWarrior.playAnimation('attack');
    } else {
      whisperWarrior.playAnimation('idle');
    }

    // 🔹 Ensure sprite updates smoothly with movement
    whisperWarrior.position = position.clone();

    // ✅ Ensure an enemy is targeted before shooting
    if (timeSinceLastShot >= (1 / attackSpeed) && closestEnemy != null) {
      print("🛑 Projectile removed: Max range exceeded");
      shootProjectile(
          closestEnemy!, damage.toInt()); // ✅ Pass required arguments
      timeSinceLastShot = 0.0; // ✅ Reset cooldown
    }

    if (healthBar != null) {
      healthBar!.position = position +
          Vector2(-healthBar!.size.x / 2, -size.y / 2 - healthBar!.size.y - 5);
    }

    for (var ability in abilities) {
      ability.onUpdate(this, dt);
    }
  }

  void gainSpiritExp(double amount) {
    while (amount > 0) {
      double remainingToLevel = spiritExpToNextLevel - spiritExp;

      if (amount >= remainingToLevel) {
        // ✅ Prevents skipping multiple levels at once
        spiritExp = spiritExpToNextLevel;
        amount -= remainingToLevel;
        spiritLevelUp(); // ✅ Level up BEFORE adding more XP
      } else {
        spiritExp += amount;
        amount = 0;
      }
    }

    // ✅ Update bar AFTER all level-up calculations
    gameRef.experienceBar
        .updateSpirit(spiritExp, spiritExpToNextLevel, spiritLevel);
  }

  void spiritLevelUp() {
    spiritLevel++;
    spiritExp -= spiritExpToNextLevel;
    spiritExpToNextLevel *= 1.2;
    updateSpiritMultiplier();
    print("✨ Spirit Level Up! New Spirit Level: $spiritLevel");
  }

  void takeDamage(int damage) async {
    // ✅ Make it async
    if (isDead) return; // Prevent extra damage when player dies

    double reducedDamage = damage * (1 - (defense / 100));

    // 🏹 **Apply Veil of the Forgotten effect if HP < 50%**
    if (equippedItems.any((item) => item is VeilOfTheForgotten) &&
        currentHealth < maxHealth * 0.5) {
      reducedDamage *= 0.8; // 🔥 Reduce damage by 20%
      print("🌀 Veil of the Forgotten active! Damage reduced.");
    }

    currentHealth -=
        reducedDamage.clamp(1, maxHealth).toInt(); // ✅ Explicit cast

    // ✅ Lose Spirit EXP instead of instantly dropping a level
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

      // ✅ Get animation duration correctly
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

  void shootProjectile(PositionComponent target, int damage,
      {bool isCritical = false}) {
    if (closestEnemy == null) {
      print("⚠️ No enemy targeted - projectile not fired!");
      return;
    }

    print("🚀 shootProjectile() called!");

    final direction = (closestEnemy!.position - position).normalized();

    final projectile = Projectile(
      damage: damage, // ✅ Ensure `damage` is an int
      velocity: direction * 500, // ✅ Now correctly passing velocity
      maxRange: 1600, // ✅ Player projectiles should have a range
      player: this, // ✅ Pass the player reference
      onHit: (enemy) {
        // ✅ Move Cursed Echo trigger here
        if (hasAbility<CursedEcho>()) {
          abilities
              .firstWhere((a) => a is CursedEcho)
              .onHit(this, enemy, damage, isCritical: isCritical);
        }
      },
    )
      ..position = position.clone()
      ..size = Vector2(50, 50)
      ..anchor = Anchor.center;

    gameRef.add(projectile);
    print("🚀 PLAYER PROJECTILE FIRED!");
  }

  void addItem(Item item) {
    inventory.add(item);
    inventoryNotifier.value = List.from(inventory); // ✅ Triggers UI update
    print("📦 Added ${item.name} to inventory.");
  }

  void addAbility(Ability ability) {
    abilities.add(ability);
    abilityNotifier.value = List.from(abilities);
    ability.applyEffect(this);
  }

  bool hasAbility<T extends Ability>() {
    return abilities.any((ability) => ability is T);
  }

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

  void gainHealth(int amount) {
    if (currentHealth < maxHealth && amount > 0) {
      int healedAmount = ((currentHealth + amount) > maxHealth)
          ? (maxHealth - currentHealth).toInt()
          : amount; // ✅ Explicit cast
      currentHealth += healedAmount;

      if (healedAmount > 0) {
        final healingNumber = HealingNumber(healedAmount, position.clone());
        gameRef.add(healingNumber);
      }
    }
  }

  void triggerExplosion(Vector2 position) {
    double currentTime = gameRef.currentTime();

    // ✅ Prevent excessive explosions
    if (currentTime - lastExplosionTime < explosionCooldown) {
      return;
    }

    lastExplosionTime = currentTime; // ✅ Update cooldown

    gameRef.add(Explosion(position));
    print("💥 Explosion triggered at $position");

    // ✅ Calculate explosion damage based on Spirit Level
    double explosionDamage = damage * 0.25; // Base: 25% of player damage
    explosionDamage *= spiritMultiplier; // Scale with Spirit Level

    // ✅ Apply damage to nearby enemies
    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;

      if (distance < 100.0) {
        // ✅ Explosion radius
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

  void addPassiveEffect(PassiveEffect passiveEffect) {}

  void removePassiveEffect(String s) {}
}
