import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/damage/damage_tracker.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/projectiles/projectile.dart';
import 'package:whisper_warriors/game/main.dart';

/// Enum for ability types (optional, for categorization)
enum AbilityType { passive, onHit, onKill, aura, scaling, projectile }

/// Base class for all abilities
abstract class Ability {
  final String name;
  final String description;
  final AbilityType type;
  final DamageReport damageReport;

  Ability({
    required this.name,
    required this.description,
    required this.type,
  }) : damageReport = DamageReport(name);

  // Override these methods for specific ability behavior
  void applyEffect(Player player) {}
  void onKill(Player player, Vector2 enemyPosition) {}
  void onUpdate(Player player, double dt) {}
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {}
}

/// 🔥 **Whispering Flames Ability** - Fire aura that damages nearby enemies
class WhisperingFlames extends Component
    with HasGameRef<RogueShooterGame>
    implements Ability {
  double _elapsedTime = 0.0;
  final double baseDamagePerSecond = 10;
  final double range = 150;
  final String name = "Whispering Flames";
  final String description = "Deals continuous damage to nearby enemies.";
  final AbilityType type = AbilityType.aura;
  final DamageReport damageReport;
  late final Player _player; // Add reference to player

  WhisperingFlames() : damageReport = DamageReport("Whispering Flames");

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _player = gameRef.player;
  }

  @override
  void update(double dt) {
    // Safety check to prevent crashes during cleanup
    if (!isMounted || parent == null) return;

    super.update(dt);
    onUpdate(_player, dt);
  }

  @override
  void onUpdate(Player player, double dt) {
    // Safety check to prevent crashes during cleanup
    if (!isMounted || parent == null) return;

    _elapsedTime += dt;
    if (_elapsedTime >= 1.0) {
      _elapsedTime = 0.0;
      double scaledDamage = baseDamagePerSecond * player.spiritMultiplier;

      // Debug print to track updates
      print(
          "🔥 WhisperingFlames updating... Range: $range, Base Damage: $baseDamagePerSecond");

      try {
        for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
          double distance = (enemy.position - player.position).length;
          if (distance < range) {
            bool isCritical =
                gameRef.random.nextDouble() < (player.critChance / 100);
            int finalDamage = isCritical
                ? (scaledDamage * player.critMultiplier).toInt()
                : scaledDamage.toInt();

            enemy.takeDamage(finalDamage, isCritical: isCritical);
            damageReport.recordHit(finalDamage, isCritical);

            print(
                "🔥 Whispering Flames hit enemy at distance $distance for $finalDamage damage (Crit: $isCritical)");
          }
        }
      } catch (e) {
        // If we get an error during cleanup, just stop processing
        print("WhisperingFlames caught error during cleanup: $e");
        return;
      }
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    // Any cleanup needed when the ability is removed
    print("🔥 WhisperingFlames removed");
  }

  @override
  void applyEffect(Player player) {}

  @override
  void onKill(Player player, Vector2 enemyPosition) {}

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {}
}

/// 🗡️ **Shadow Blades Ability Controller**
class ShadowBlades extends PositionComponent implements Ability {
  final DamageTracker damageTracker = DamageTracker();
  double _timeSinceLastTick = 0;
  final double tickInterval = 0.5;
  final double range = 150;
  final int damage = 75;

  @override
  final String name = 'Shadow Blades';

  @override
  final String description =
      'Summons ethereal blades that damage nearby enemies';

  @override
  final AbilityType type = AbilityType.passive;

  ShadowBlades() {
    damageTracker.initialize();
  }

  @override
  void onMount() {
    super.onMount();
    print('🗡️ Shadow Blades mounted');
  }

  @override
  void onUpdate(Player player, double dt) {
    print('🗡️ Shadow Blades update: ${player.position}');

    _timeSinceLastTick += dt;
    if (_timeSinceLastTick >= tickInterval) {
      _timeSinceLastTick = 0;

      // Find closest enemy
      BaseEnemy? target = findClosestEnemy(player);
      if (target != null) {
        print('🎯 Found target at: ${target.position}');

        // Calculate direction to enemy
        final direction = (target.position - player.position).normalized();
        final rotationAngle = direction.angleToSigned(Vector2(1, 0));

        // Create and shoot projectile
        final projectile = ShadowBladeProjectile(
          player: player,
          ability: this,
          velocity: direction * 500,
          rotationAngle: rotationAngle,
          damage: damage,
        )..position = player.position.clone();

        player.gameRef.add(projectile);
        print('🗡️ Shot blade at target');

        // Roll Cursed Echo ONCE per blade thrown
        if (player.hasAbility<CursedEcho>()) {
          double procChance = 0.20; // 20% chance
          if (player.gameRef.random.nextDouble() < procChance) {
            print("🔄 Cursed Echo triggered for Shadow Blade!");
            Future.delayed(Duration(milliseconds: 100), () {
              player.gameRef.add(ShadowBladeProjectile(
                player: player,
                ability: this,
                damage: (damage * player.spiritMultiplier).toInt(),
                velocity: direction * 500,
                rotationAngle: rotationAngle,
              )..position = player.position.clone());
            });
          } else {
            print("❌ Cursed Echo failed to proc for Shadow Blade");
          }
        }
      } else {
        print('⚠️ No target found');
      }
    }
  }

  BaseEnemy? findClosestEnemy(Player player) {
    double closestDistance = double.infinity;
    BaseEnemy? closestEnemy;

    for (final enemy in player.gameRef.children.whereType<BaseEnemy>()) {
      final distance = enemy.position.distanceTo(player.position);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestEnemy = enemy;
      }
    }

    return closestEnemy;
  }

  @override
  void applyEffect(Player player) {
    // No permanent effects to apply
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    damageTracker.logDamage(name, damage, isCritical);
  }

  @override
  void onKill(Player player, Vector2 position) {
    // No special kill effects
  }

  @override
  DamageReport get damageReport {
    return DamageReport(name);
  }
}

/// 🗡️ **Shadow Blade Projectile Component**
class ShadowBladeProjectile extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final ShadowBlades ability;
  final double bladeSpeed = 750;
  double maxDistance = 1200;
  Vector2 startPosition = Vector2.zero();
  final Vector2 velocity;
  final double rotationAngle;
  final int damage;
  late final RectangleHitbox hitbox;

  // Track which enemies we've hit to prevent multiple hits
  final Set<BaseEnemy> hitEnemies = {};

  ShadowBladeProjectile({
    required this.player,
    required this.ability,
    required this.velocity,
    required this.rotationAngle,
    required this.damage,
  }) : super(size: Vector2(32, 32));

  @override
  Future<void> onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
      'shadowblades.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2.all(32),
      ),
    );

    hitbox = RectangleHitbox(
      size: Vector2(24, 24),
      position: Vector2(4, 4),
    );
    add(hitbox);

    startPosition = position.clone();
    angle = rotationAngle;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;

    if (position.distanceTo(startPosition) > maxDistance) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BaseEnemy && !hitEnemies.contains(other)) {
      print('🗡️ Shadow Blade pierced enemy!'); // Debug print

      // Add enemy to hit list
      hitEnemies.add(other);

      // Calculate critical hit
      bool isCritical =
          player.gameRef.random.nextDouble() < (player.critChance / 100);
      int finalDamage = isCritical
          ? (damage * (1 + player.critMultiplier / 100)).toInt()
          : damage;

      // Apply damage
      other.takeDamage(finalDamage);

      // Notify ability of hit
      ability.onHit(player, other, finalDamage, isCritical: isCritical);

      // Don't remove the projectile - let it continue flying
    }
  }
}

/// 🔁 **Cursed Echo Ability** - Chance to repeat attacks
class CursedEcho extends Ability {
  static const double BASE_PROC_CHANCE = 0.35; // Increased to 35%
  static const double DELAY_BETWEEN_REPEATS = 0.1; // 100ms delay
  static const double PROC_COOLDOWN = 0.5; // Reduced to 0.5s cooldown
  double _lastProcTime = 0.0;

  CursedEcho()
      : super(
          name: "Cursed Echo",
          description:
              "Every attack has a chance to repeat itself, increasing with Spirit Level.",
          type: AbilityType.onHit,
        );

  double getProcChance(Player player) {
    double chance =
        (BASE_PROC_CHANCE + (player.spiritLevel * 0.01)).clamp(0, 1);
    print(
        '🎲 Cursed Echo base chance: ${(BASE_PROC_CHANCE * 100).toStringAsFixed(1)}%');
    print(
        '🌟 Spirit Level bonus: +${(player.spiritLevel).toStringAsFixed(1)}%');
    print('✨ Final proc chance: ${(chance * 100).toStringAsFixed(1)}%');
    return chance;
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    double currentTime = player.gameRef.currentTime();
    double timeSinceLastProc = currentTime - _lastProcTime;

    print('⚡ Cursed Echo checking hit...');
    print('⏱️ Time since last proc: ${timeSinceLastProc.toStringAsFixed(2)}s');
    print(
        '⌛ Cooldown remaining: ${(PROC_COOLDOWN - timeSinceLastProc).toStringAsFixed(2)}s');

    if (timeSinceLastProc < PROC_COOLDOWN) {
      print(
          '❌ Cursed Echo on cooldown (${(PROC_COOLDOWN - timeSinceLastProc).toStringAsFixed(2)}s remaining)');
      return;
    }

    double procChance = getProcChance(player);
    double roll = player.gameRef.random.nextDouble();
    print('🎲 Rolling: $roll vs ${procChance.toStringAsFixed(2)}');

    if (roll < procChance) {
      _lastProcTime = currentTime;
      print(
          '✨ Cursed Echo triggered! (Roll: $roll < ${procChance.toStringAsFixed(2)})');

      Future.delayed(
          Duration(milliseconds: (DELAY_BETWEEN_REPEATS * 1000).toInt()), () {
        if (target.isMounted) {
          // Calculate echo damage (same as original)
          int echoDamage = (damage * player.spiritMultiplier).toInt();

          // Record the echoed hit
          damageReport.recordHit(echoDamage, isCritical);
          print('💥 Cursed Echo dealt $echoDamage damage (Crit: $isCritical)');

          // Apply the damage
          if (target is BaseEnemy) {
            target.takeDamage(echoDamage, isCritical: isCritical);
          }
        } else {
          print('⚠️ Target no longer exists for Cursed Echo');
        }
      });
    } else {
      print(
          '❌ Cursed Echo failed to proc (Roll: $roll >= ${procChance.toStringAsFixed(2)})');
    }
  }
}

/// 💥 **Soul Fracture Ability** - Enemies explode on death
class SoulFracture extends Ability {
  SoulFracture()
      : super(
          name: "Soul Fracture",
          description: "Enemies explode into ghostly shrapnel on death.",
          type: AbilityType.onKill,
        );

  @override
  void onKill(Player player, Vector2 enemyPosition) {
    if (!player.hasTriggeredExplosionRecently()) {
      player.triggerExplosion(enemyPosition);
    }
  }
}

/// 💣 **Explosion Scaling** - Scales explosion damage with Spirit Level
extension ExplosionCooldown on Player {
  bool hasTriggeredExplosionRecently() {
    double currentTime = gameRef.currentTime();
    if (currentTime - lastExplosionTime < explosionCooldown) {
      return true;
    }
    lastExplosionTime = currentTime;
    return false;
  }

  void triggerExplosion(Vector2 position) {
    if (hasTriggeredExplosionRecently()) return;
    gameRef.add(Explosion(position));
    print("💥 Spirit Explosion triggered!");

    for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
      double distance = (enemy.position - position).length;
      if (distance < 100.0) {
        int damage = (10.0 * spiritMultiplier).toInt().clamp(1, 9999);
        enemy.takeDamage(damage);
      }
    }
  }
}

class DamageReport {
  final String abilityName;
  int totalDamage = 0;
  int hits = 0;
  int criticalHits = 0;

  DamageReport(this.abilityName);

  double get averageDamage => hits > 0 ? totalDamage / hits : 0;
  double get critRate => hits > 0 ? (criticalHits / hits) * 100 : 0;

  void recordHit(int damage, bool isCritical) {
    totalDamage += damage;
    hits++;
    if (isCritical) criticalHits++;

    // Debug print to verify recording
    print('📊 $abilityName recorded hit: $damage damage (Crit: $isCritical)');
    print('   Total: $totalDamage | Hits: $hits | Crits: $criticalHits');
  }

  @override
  String toString() {
    return '''
🎯 $abilityName Stats:
   Total Damage: $totalDamage
   Hits: $hits
   Critical Hits: $criticalHits (${critRate.toStringAsFixed(1)}%)
   Average Damage: ${averageDamage.toStringAsFixed(1)}
''';
  }
}
