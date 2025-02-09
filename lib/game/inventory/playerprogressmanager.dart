import 'package:hive/hive.dart';

class PlayerProgressManager {
  static final Box _progressBox = Hive.box('playerProgressBox');

  // Load XP (default to 0)
  static int getXp() => _progressBox.get('xp', defaultValue: 0);

  // Save XP
  static void setXp(int xp) {
    _progressBox.put('xp', xp);
    print("💾 XP Updated: $xp");
  }

  // Load Level (default to 1)
  static int getLevel() => _progressBox.get('level', defaultValue: 1);

  // Save Level
  static void setLevel(int level) {
    _progressBox.put('level', level);
    print("📈 Level Updated: $level");
  }

  // Grant XP and check if player levels up
  static void addXp(int amount) {
    int currentXp = getXp();
    int newXp = currentXp + amount;
    setXp(newXp);

    // Check if player should level up
    checkForLevelUp();
  }

  // XP needed for next level (simple curve, adjust if needed)
  static int xpForNextLevel(int level) {
    return 100 * level; // Example: Level 2 needs 200 XP, Level 3 needs 300 XP
  }

  static void checkForLevelUp() {
    int currentLevel = getLevel();
    int currentXp = getXp();
    int requiredXp = xpForNextLevel(currentLevel);

    if (currentXp >= requiredXp) {
      setLevel(currentLevel + 1);
      setXp(0); // Reset XP after level-up
      print("🎉 Player Leveled Up to Level ${currentLevel + 1}!");
    }
  }
}
