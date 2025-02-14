import 'package:hive_flutter/hive_flutter.dart';
import 'ability_damage_log.dart';

class DamageTracker {
  // Use the same box names as defined in main.dart
  static const String damageLogsBoxName = 'ability_damage_logs';
  final String source;
  static late Box<AbilityDamageLog> _damageBox;
  static bool _isInitialized = false;

  DamageTracker(this.source);

  static Future<void> initialize() async {
    // Register the adapter if not already registered
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AbilityDamageLogAdapter());
    }

    // Open the box
    _damageBox = await Hive.openBox<AbilityDamageLog>('ability_damage_logs');
    print('📊 Damage tracking initialized');
  }

  bool get isInitialized => _isInitialized;

  void recordDamage(int damage, {bool isCritical = false}) {
    try {
      if (!_damageBox.isOpen) {
        print('⚠️ Damage box is not open, attempting to reopen...');
        initialize();
        return;
      }

      final String key = '${source}_damage_log';
      AbilityDamageLog log = _damageBox.get(key) ??
          AbilityDamageLog(source); // Use the simple constructor

      // Update the log values
      log.totalDamage += damage;
      log.hits++;
      if (isCritical) log.criticalHits++;

      _damageBox.put(key, log);
      print(
          '📊 Recorded damage for ${log.abilityName}: $damage (Critical: $isCritical)');
    } catch (e) {
      print('❌ Error recording damage: $e');
    }
  }

  List<AbilityDamageLog> getAllLogs() {
    if (!_damageBox.isOpen) {
      print('⚠️ Warning: Trying to get logs before initialization');
      return [];
    }
    return _damageBox.values.toList();
  }

  Future<void> clearGameData() async {
    if (!_isInitialized) {
      await initialize();
    }
    await _damageBox.clear();
    print('🧹 Cleared all damage logs');
  }

  String generateReport() {
    final logs = getAllLogs();
    if (logs.isEmpty) return 'No damage data recorded.';

    int totalGameDamage = 0;
    double totalCritRate = 0;
    int totalHits = 0;
    int totalCrits = 0;

    StringBuffer report = StringBuffer();
    report.writeln('📊 Damage Report\n================\n');

    // Sort abilities by total damage
    logs.sort((a, b) => b.totalDamage.compareTo(a.totalDamage));

    for (var log in logs) {
      totalGameDamage += log.totalDamage;
      totalHits += log.hits;
      totalCrits += log.criticalHits;

      double avgDamage = log.hits > 0 ? log.totalDamage / log.hits : 0;
      double critRate = log.hits > 0 ? (log.criticalHits / log.hits) * 100 : 0;

      report.writeln('🎯 ${log.abilityName}:');
      report.writeln('   Total Damage: ${log.totalDamage}');
      report.writeln('   Hits: ${log.hits}');
      report.writeln(
          '   Critical Hits: ${log.criticalHits} (${critRate.toStringAsFixed(1)}%)');
      report.writeln('   Average Damage: ${avgDamage.toStringAsFixed(1)}');
      report.writeln('');
    }

    // Overall stats
    totalCritRate = totalHits > 0 ? (totalCrits / totalHits) * 100 : 0;
    report.writeln('================\n');
    report.writeln('📈 Overall Stats:');
    report.writeln('   Total Game Damage: $totalGameDamage');
    report.writeln('   Total Hits: $totalHits');
    report.writeln(
        '   Total Crits: $totalCrits (${totalCritRate.toStringAsFixed(1)}%)');

    return report.toString();
  }

  void logDamage(String abilityName, int damage, bool isCritical) async {
    try {
      if (!Hive.isBoxOpen('ability_damage_logs')) {
        await Hive.openBox<AbilityDamageLog>('ability_damage_logs');
      }

      final damageLogsBox = Hive.box<AbilityDamageLog>('ability_damage_logs');
      var existingLog =
          damageLogsBox.get(abilityName) ?? AbilityDamageLog(abilityName);

      existingLog.totalDamage += damage;
      existingLog.hits++;
      if (isCritical) {
        existingLog.criticalHits++;
      }
      await damageLogsBox.put(abilityName, existingLog);
      print(
          '📝 Logged damage for $abilityName: $damage (Critical: $isCritical)');
    } catch (e) {
      print('❌ Error logging damage: $e');
    }
  }

  String generateDamageReport() {
    StringBuffer report = StringBuffer();
    report.writeln('📊 Damage Report');
    report.writeln('================\n');

    int totalDamage = 0;

    // Make sure to include BasicAttack first
    final basicAttackReport = _damageBox.get('Basic Attack');
    if (basicAttackReport != null) {
      report.writeln('Basic Attack:');
      report.writeln('  Total Damage: ${basicAttackReport.totalDamage}');
      report.writeln('  Hits: ${basicAttackReport.hits}');
      report.writeln('  Critical Hits: ${basicAttackReport.criticalHits}\n');
      totalDamage += basicAttackReport.totalDamage;
    }

    // Then include all other abilities
    _damageBox.toMap().forEach((key, value) {
      if (key != 'Basic Attack') {
        report.writeln('$key:');
        report.writeln('  Total Damage: ${value.totalDamage}');
        report.writeln('  Hits: ${value.hits}');
        report.writeln('  Critical Hits: ${value.criticalHits}\n');
        totalDamage += value.totalDamage;
      }
    });

    report.writeln('\n🔥 Total Game Damage: $totalDamage');

    return report.toString();
  }

  static Future<void> clearAllDamageData() async {
    try {
      if (_damageBox.isOpen) {
        await _damageBox.clear();
        print('🧹 Damage data cleared');
      }
    } catch (e) {
      print('❌ Error clearing damage data: $e');
    }
  }

  @override
  void dispose() async {
    if (_damageBox.isOpen) {
      await _damageBox.close();
    }
  }
}
