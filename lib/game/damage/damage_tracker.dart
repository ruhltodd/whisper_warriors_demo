import 'package:hive/hive.dart';
import 'ability_damage_log.dart';

class DamageTracker {
  static const String boxName = 'damage_logs';
  late Box<AbilityDamageLog> _damageBox;
  static bool _isInitialized = false;
  static final DamageTracker _instance = DamageTracker._internal();

  DamageTracker._internal();

  factory DamageTracker() {
    return _instance;
  }

  Future<void> initialize() async {
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AbilityDamageLogAdapter());
      }
      print('✅ DamageTracker initialized');
    } catch (e) {
      print('❌ Error initializing DamageTracker: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> recordDamage(
      String abilityName, int damage, bool isCritical) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      var log = _damageBox.get(abilityName) ?? AbilityDamageLog(abilityName);
      log.totalDamage += damage;
      log.hits++;
      if (isCritical) log.criticalHits++;
      await _damageBox.put(abilityName, log);
      print(
          '📝 Recorded damage for $abilityName: $damage (Critical: $isCritical)');
    } catch (e) {
      print('❌ Error recording damage: $e');
    }
  }

  List<AbilityDamageLog> getAllLogs() {
    if (!_isInitialized) {
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
}
