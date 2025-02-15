import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/abilities/abilityfactory.dart';
import 'package:flutter/foundation.dart';

class PlayerProgressManager {
  static const String progressBoxName =
      'playerprogressbox'; // Match the name in main.dart
  static late Box _progressBox;
  static bool _isInitialized = false;
  static const int MAX_SPIRIT_LEVEL = 30; // Reasonable max level
  static const double MAX_SPIRIT_MULTIPLIER = 6.0; // 5x base + 1.0
  static double _lastPrintTime = 0;
  static const double PRINT_INTERVAL = 1.0; // Only print once per second

  // Session-based spirit stats
  static int _sessionSpiritLevel = 1;
  static double _sessionSpiritExp = 0.0;
  static double _sessionSpiritExpToNextLevel = 500.0;
  static double _sessionSpiritItemBonus = 0.0;

  // Add notifiers for UI updates
  static final ValueNotifier<double> spiritExpNotifier =
      ValueNotifier<double>(0.0);
  static final ValueNotifier<int> spiritLevelNotifier = ValueNotifier<int>(1);

  static Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        if (!Hive.isBoxOpen(progressBoxName)) {
          _progressBox = await Hive.openBox(progressBoxName);
        } else {
          _progressBox = Hive.box(progressBoxName);
        }
        _isInitialized = true;

        // Remove old Spirit Level & XP from Hive (only keep main XP/level)
        _progressBox.delete('spiritLevel');
        _progressBox.delete('spiritExp');
        _progressBox.delete('spiritExpToNextLevel');
        _progressBox.delete('spiritItemBonus');

        print('🧹 Old Spirit data cleared from Hive!');

        // Reset session-based Spirit Level values
        _sessionSpiritLevel = 1;
        _sessionSpiritExp = 0.0;
        _sessionSpiritExpToNextLevel = 250.0;
        _sessionSpiritItemBonus = 0.0;

        print('🔄 Spirit Level reset to 1 for this session');
      } catch (e) {
        print('❌ Error initializing PlayerProgressManager: $e');
        await Hive.deleteBoxFromDisk(progressBoxName);
        _progressBox = await Hive.openBox(progressBoxName);
        _isInitialized = true;
      }
    }
  }

  // ✅ Temporary XP/Level Reset (Does NOT modify Hive)
  static void resetProgressForTestingTemporary() {
    print("🧪 TEMP Debug: Forcing Level 1 (Session-Only)");
    int tempLevel = 1;
    int tempXp = 0;

    print("🌟 Debug Level: $tempLevel | Debug XP: $tempXp");
  }

  // Load XP (default to 0)
  static int getXp() {
    if (!_isInitialized) {
      print('⚠️ Warning: Accessing progress before initialization');
      return 0;
    }
    return _progressBox.get('xp', defaultValue: 0);
  }

  // Save XP
  static void setXp(int xp) {
    if (!_isInitialized) {
      print('⚠️ Warning: Setting XP before initialization');
      return;
    }
    _progressBox.put('xp', xp);
    print("💾 XP Updated: $xp");
  }

  // Load Level (default to 1)
  static int getLevel() {
    if (!_isInitialized) {
      print('⚠️ Warning: Accessing level before initialization');
      return 1;
    }
    return _progressBox.get('level', defaultValue: 1);
  }

  // Save Level
  static void setLevel(int level) {
    if (!_isInitialized) {
      print('⚠️ Warning: Setting level before initialization');
      return;
    }
    _progressBox.put('level', level);
    print("📈 Level Updated: $level");
  }

  // Get unlocked abilities from Hive
  static List<String> getUnlockedAbilities() {
    int currentLevel = getLevel();

    // ✅ Unlock abilities dynamically based on level
    List<String> unlocked = AbilityFactory.abilityUnlockOrder
        .take(currentLevel) // Take abilities up to the player's level
        .toList();

    print("🔓 Unlocked Abilities: $unlocked");
    return unlocked;
  }

  // Save unlocked abilities to Hive
  static void saveUnlockedAbilities(List<String> abilities) {
    _progressBox.put('unlockedAbilities', abilities);
    print("🔓 Unlocked Abilities: $abilities");
  }

  // Grant XP and check for level up
  static void addXp(int amount) {
    int currentXp = getXp();
    int newXp = currentXp + amount;
    setXp(newXp);

    // Check if player should level up
    checkForLevelUp();
  }

  // XP needed for next level
  static int xpForNextLevel(int level) {
    return 100 * level; // Adjust this formula as needed
  }

  static void checkForLevelUp() {
    int currentLevel = getLevel();
    int currentXp = getXp();
    int requiredXp = xpForNextLevel(currentLevel);

    if (currentXp >= requiredXp) {
      setLevel(currentLevel + 1);
      setXp(0); // Reset XP after level-up
      print("🎉 Player Leveled Up to Level ${currentLevel + 1}!");

      // ✅ Check if a new ability is available at this level
      List<String> unlockedAbilities = getUnlockedAbilities();
      if (unlockedAbilities.length >= currentLevel) {
        print(
            "🔓 New Ability Unlocked: ${unlockedAbilities[currentLevel - 1]}!");
      }
    }
  }

// 🔥 Unlock an ability when leveling up
  static void unlockAbilityForLevel(int level) {
    // ✅ Only include the abilities we actually have implemented
    List<String> availableAbilities = [
      "Whispering Flames",
      "Soul Fracture",
      "Shadow Blades",
      "Cursed Echo"
    ];

    List<String> unlockedAbilities = getUnlockedAbilities();

    // ✅ Ensure we don't exceed the implemented abilities
    if (level <= availableAbilities.length) {
      String newAbility =
          availableAbilities[level - 1]; // Level 1 unlocks 1st ability, etc.
      if (!unlockedAbilities.contains(newAbility)) {
        unlockedAbilities.add(newAbility);
        saveUnlockedAbilities(unlockedAbilities);
        print("✨ Unlocked New Ability: $newAbility");
      }
    } else {
      print("⚠️ No more abilities to unlock at level $level!");
    }
  }

  // For player stats and abilities
  static double getSpiritMultiplier() {
    // Base multiplier from spirit level (2% per level instead of 5%)
    double baseMultiplier = 1.0 + (getSpiritLevel() * 0.02);

    // Limit item bonus to 1.5x max
    double itemBonus = _sessionSpiritItemBonus.clamp(0.0, 1.5);

    // Calculate final multiplier (additive with item bonus)
    double finalMultiplier =
        (baseMultiplier * (1 + itemBonus)).clamp(1.0, MAX_SPIRIT_MULTIPLIER);

    // Rate-limited debug print
    double currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
    if (currentTime - _lastPrintTime >= PRINT_INTERVAL) {
      print('🌟 Spirit Level: ${getSpiritLevel()}');
      print('🌟 Base Multiplier: ${baseMultiplier.toStringAsFixed(2)}x');
      print('🌟 Item Bonus: ${itemBonus.toStringAsFixed(2)}x');
      print('🌟 Final Multiplier: ${finalMultiplier.toStringAsFixed(2)}x');
      _lastPrintTime = currentTime;
    }

    return finalMultiplier;
  }

  // For enemy scaling (no item bonuses, different scaling formula)
  static double getEnemyScaling() {
    double baseMultiplier = 1.0 + (getSpiritLevel() * 0.025);
    // Clamp enemy scaling too
    baseMultiplier =
        baseMultiplier.clamp(1.0, 3.0); // Max 3x scaling for enemies
    print(
        '👾 Enemy Scaling: ${baseMultiplier.toStringAsFixed(2)}x (Level ${getSpiritLevel()})');
    return baseMultiplier;
  }

  static int getSpiritLevel() {
    return _sessionSpiritLevel;
  }

  static double getSpiritExp() {
    return _sessionSpiritExp;
  }

  static double getSpiritExpToNextLevel() {
    return _sessionSpiritExpToNextLevel;
  }

  static void setSpiritLevel(int level) {
    _sessionSpiritLevel = level;
  }

  static void setSpiritExp(double exp) {
    _sessionSpiritExp = exp;
  }

  static void setSpiritExpToNextLevel(double exp) {
    _sessionSpiritExpToNextLevel = exp;
  }

  static void setSpiritItemBonus(double bonus) {
    if (!_isInitialized) {
      print('⚠️ Warning: Setting spirit item bonus before initialization');
      return;
    }

    // Clamp the bonus to prevent excessive stacking
    double newBonus = (bonus).clamp(0.0, 2.0); // Max 2x bonus cap

    _progressBox.put('spiritItemBonus', newBonus);
    print('🌟 Spirit Item Bonus updated: ${newBonus.toStringAsFixed(2)}x');
  }

  static void gainSpiritExp(double amount) {
    if (getSpiritLevel() >= MAX_SPIRIT_LEVEL) {
      print('⚠️ Already at maximum spirit level ($MAX_SPIRIT_LEVEL)!');
      return;
    }

    // Calculate adjusted XP gain
    double scalingFactor = 1.0 / (1.0 + (getSpiritLevel() * 0.2));
    double adjustedAmount = (amount * 0.3) * scalingFactor;

    double currentExp = getSpiritExp();
    double expToNext = getSpiritExpToNextLevel();
    int levelUps = 0;

    while (adjustedAmount > 0 && levelUps < 3) {
      double remainingToLevel = expToNext - currentExp;

      if (adjustedAmount >= remainingToLevel) {
        if (getSpiritLevel() >= MAX_SPIRIT_LEVEL) {
          setSpiritExp(0);
          return;
        }
        currentExp = 0;
        adjustedAmount -= remainingToLevel;
        spiritLevelUp();
        expToNext = getSpiritExpToNextLevel();
        levelUps++;
      } else {
        currentExp += adjustedAmount;
        adjustedAmount = 0;
      }
    }

    if (levelUps >= 3) {
      print("⚠️ Max 3 level-ups per gainSpiritExp call. Excess XP lost.");
    }

    setSpiritExp(currentExp);

    // Update UI notifiers
    spiritExpNotifier.value = currentExp / getSpiritExpToNextLevel();
    spiritLevelNotifier.value = getSpiritLevel();

    print(
        "💾 Spirit XP Gained: ${(amount * scalingFactor).toStringAsFixed(1)} (Scaling: ${scalingFactor.toStringAsFixed(2)}x)");
  }

  static void spiritLevelUp() {
    int currentLevel = getSpiritLevel();

    // Prevent leveling past max
    if (currentLevel >= MAX_SPIRIT_LEVEL) {
      print('⚠️ Maximum spirit level ($MAX_SPIRIT_LEVEL) reached!');
      setSpiritExp(0); // Reset excess XP
      return;
    }

    setSpiritLevel(currentLevel + 1);
    setSpiritExp(0);

    // Prevent XP scaling overflow with reasonable limits
    double newExpToNext = (getSpiritExpToNextLevel() * 1.5)
        .clamp(250, 9999999); // Steeper XP curve (1.5 instead of 1.2)
    setSpiritExpToNextLevel(newExpToNext);

    print(
        '🎉 Spirit Level Up! Now level ${currentLevel + 1}/$MAX_SPIRIT_LEVEL');
    print('⚡ Next Level XP Requirement: ${newExpToNext.toStringAsFixed(2)}');
  }

  // Spirit Item Bonus methods
  static double getSpiritItemBonus() {
    if (!_isInitialized) {
      print('⚠️ Warning: Accessing spirit item bonus before initialization');
      return 0.0;
    }
    return _progressBox.get('spiritItemBonus', defaultValue: 0.0);
  }

  // Don't forget to dispose notifiers when done
  static void dispose() {
    spiritExpNotifier.dispose();
    spiritLevelNotifier.dispose();
  }
}
