import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/abilities/abilityfactory.dart';

class PlayerProgressManager {
  static const String progressBoxName =
      'playerprogressbox'; // Match the name in main.dart
  static late Box _progressBox;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      if (!Hive.isBoxOpen(progressBoxName)) {
        _progressBox = await Hive.openBox(progressBoxName);
      } else {
        _progressBox = Hive.box(progressBoxName);
      }
      _isInitialized = true;
      print('✅ PlayerProgressManager initialized');
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
}
