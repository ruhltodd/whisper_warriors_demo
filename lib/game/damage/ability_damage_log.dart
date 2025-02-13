import 'package:hive/hive.dart';

part 'ability_damage_log.g.dart';

@HiveType(typeId: 7)
class AbilityDamageLog extends HiveObject {
  @HiveField(0)
  final String abilityName;

  @HiveField(1)
  int totalDamage = 0;

  @HiveField(2)
  int hits = 0;

  @HiveField(3)
  int criticalHits = 0;

  AbilityDamageLog(this.abilityName);

  @override
  String toString() {
    return '$abilityName - Total Damage: $totalDamage, Hits: $hits, Crits: $criticalHits';
  }
}
