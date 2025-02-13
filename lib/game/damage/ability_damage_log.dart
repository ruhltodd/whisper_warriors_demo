import 'package:hive/hive.dart';

part 'ability_damage_log.g.dart';

@HiveType(typeId: 50)
class AbilityDamageLog extends HiveObject {
  @HiveField(0)
  final String abilityName;

  @HiveField(1)
  int totalDamage;

  @HiveField(2)
  int hits;

  @HiveField(3)
  int criticalHits;

  AbilityDamageLog(
    this.abilityName, {
    this.totalDamage = 0,
    this.hits = 0,
    this.criticalHits = 0,
  });

  @override
  String toString() {
    return '$abilityName - Total Damage: $totalDamage, Hits: $hits, Crits: $criticalHits';
  }
}
