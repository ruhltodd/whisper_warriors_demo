import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:whisper_warriors/game/damage/damage_tracker.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';

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
  final DamageTracker damageTracker;
  double _elapsedTime = 0.0;
  final double baseDamagePerSecond = 225;
  final double range = 450;
  final double tickRate = 0.5;

  @override
  final String name = "Whispering Flames";

  @override
  final String description = "Deals continuous damage to nearby enemies.";

  @override
  final AbilityType type = AbilityType.aura;

  @override
  final DamageReport damageReport;

  late final Player _player;

  WhisperingFlames()
      : damageTracker = DamageTracker("Whispering Flames"),
        damageReport = DamageReport("Whispering Flames") {
    DamageTracker.initialize();
    print('🔥 WhisperingFlames initialized with Hive damage tracker');
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _player = gameRef.player;
    print('🔥 WhisperingFlames loaded'); // Debug mount
  }

  @override
  void onMount() {
    super.onMount();
    print('🔥 WhisperingFlames mounted'); // Debug mount
  }

  @override
  void update(double dt) {
    if (!isMounted || parent == null) {
      print('🔥 WhisperingFlames not mounted or no parent');
      return;
    }
    super.update(dt);

    _elapsedTime += dt;
    if (_elapsedTime >= tickRate) {
      _elapsedTime = 0.0;
      double spiritMultiplier = PlayerProgressManager.getSpiritMultiplier();
      double scaledDamage = baseDamagePerSecond * spiritMultiplier;

      // Rate-limited debug print
      if (_shouldPrintDebug()) {
        print('🔥 WhisperingFlames tick');
        print(
            '🔥 Base damage: $baseDamagePerSecond × ${spiritMultiplier.toStringAsFixed(2)} = $scaledDamage');
      }

      try {
        int enemiesInRange = 0;
        for (var enemy in gameRef.children.whereType<BaseEnemy>()) {
          // Skip non-targetable enemies
          if (!enemy.isTargetable) continue;

          double distance = (enemy.position - _player.position).length;
          if (distance < range) {
            enemiesInRange++;
            bool isCritical =
                gameRef.random.nextDouble() < (_player.critChance / 100);
            int finalDamage = isCritical
                ? (scaledDamage * _player.critMultiplier).toInt()
                : scaledDamage.toInt();

            print(
                '🔥 WhisperingFlames hitting enemy at distance $distance with $finalDamage damage (Crit: $isCritical)');
            enemy.takeDamage(finalDamage.toDouble(), isCritical: isCritical);

            // Add damage number with orange numbers
            gameRef.add(DamageNumber(
              finalDamage,
              enemy.position,
              isCritical: isCritical,
              isWhisperingFlames: true,
              customSize: Vector2(10, 11), // This will use orange numbers
            ));

            // Use onHit to record the damage
            onHit(_player, enemy, finalDamage, isCritical: isCritical);
          }
        }
        if (enemiesInRange > 0) {
          print(
              '🔥 WhisperingFlames found $enemiesInRange targetable enemies in range');
        }
      } catch (e) {
        print("🔥 WhisperingFlames caught error during update: $e");
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
  void applyEffect(Player player) {
    print('🔥 WhisperingFlames applyEffect called');
    // Add this component to the game when the ability is applied
    if (!player.gameRef.children
        .whereType<WhisperingFlames>()
        .any((element) => element == this)) {
      print('🔥 Adding WhisperingFlames component to game');
      player.gameRef.add(this);
    } else {
      print('🔥 WhisperingFlames component already exists');
    }
  }

  @override
  void onKill(Player player, Vector2 enemyPosition) {}

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    if (player.hasEffect('NoAttacks')) return; // Skip if attacks are disabled

    print(
        '🔥 WhisperingFlames recording hit to Hive: $damage (Crit: $isCritical)');
    damageTracker.logDamage(name, damage, isCritical);
  }

  @override
  void onUpdate(Player player, double dt) {
    // The actual update logic is handled in the Component's update() method
    // This is just to satisfy the Ability interface
  }

  double _lastDebugPrint = 0;
  bool _shouldPrintDebug() {
    double currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
    if (currentTime - _lastDebugPrint >= 1.0) {
      _lastDebugPrint = currentTime;
      return true;
    }
    return false;
  }
}

/// 🗡️ **Shadow Blades Ability Controller**
class ShadowBlades extends PositionComponent implements Ability {
  final DamageTracker damageTracker;
  double _timeSinceLastTick = 0;
  final double tickInterval = 0.5;
  final double range = 150;
  final int baseDamage = 75; // Changed to baseDamage

  @override
  final String name = 'Shadow Blades';

  @override
  final String description =
      'Summons ethereal blades that damage nearby enemies';

  @override
  final AbilityType type = AbilityType.passive;

  ShadowBlades() : damageTracker = DamageTracker("Shadow Blades") {
    DamageTracker.initialize();
  }

  @override
  void onMount() {
    super.onMount();
    print('🗡️ Shadow Blades mounted');
  }

  @override
  void onUpdate(Player player, double dt) {
    _timeSinceLastTick += dt;
    if (_timeSinceLastTick >= tickInterval) {
      _timeSinceLastTick = 0;

      // Use player's closestEnemy instead of finding our own
      if (player.closestEnemy != null) {
        final direction =
            (player.closestEnemy!.position - player.position).normalized();
        final rotationAngle = direction.angleToSigned(Vector2(1, 0));

        // Calculate damage with spirit multiplier
        double spiritMultiplier = PlayerProgressManager.getSpiritMultiplier();
        int scaledDamage = (baseDamage * spiritMultiplier).toInt();

        final projectile = ShadowBladeProjectile(
          player: player,
          ability: this,
          velocity: direction * 500,
          rotationAngle: rotationAngle,
          damage: scaledDamage,
        )..position = player.position.clone();

        player.gameRef.add(projectile);
        print('🗡️ Shot blade at target with $scaledDamage damage');

        // Roll Cursed Echo
        if (player.hasAbility<CursedEcho>()) {
          double procChance = 0.35; // Match CursedEcho.BASE_PROC_CHANCE
          double roll = player.gameRef.random.nextDouble();
          print('🎲 Shadow Blade Cursed Echo Roll: $roll vs $procChance');

          if (roll < procChance) {
            print("🔄 Cursed Echo triggered for Shadow Blade!");
            Future.delayed(Duration(milliseconds: 100), () {
              player.gameRef.add(ShadowBladeProjectile(
                player: player,
                ability: this,
                damage: scaledDamage, // Use same scaled damage for echo
                velocity: direction * 500,
                rotationAngle: rotationAngle,
              )..position = player.position.clone());
            });
          } else {
            print(
                "❌ Cursed Echo failed to proc for Shadow Blade (Roll: $roll)");
          }
        }
      }
    }
  }

  @override
  void applyEffect(Player player) {
    // No permanent effects to apply
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    if (player.hasEffect('NoAttacks')) return; // Skip if attacks are disabled

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
      other.takeDamage(finalDamage.toDouble());

      // Notify ability of hit
      ability.onHit(player, other, finalDamage, isCritical: isCritical);

      // Don't remove the projectile - let it continue flying
    }
  }
}

/// 🔁 **Cursed Echo Ability** - Chance to repeat attacks
class CursedEcho extends Ability {
  static const double BASE_PROC_CHANCE = 0.35; // 35% base chance
  static const double DELAY_BETWEEN_REPEATS = 0.1; // 100ms delay
  static const double PROC_COOLDOWN = 0.75; // 750ms cooldown
  double _lastProcTime = 0.0;

  CursedEcho()
      : super(
          name: "Cursed Echo",
          description:
              "Every attack has a chance to repeat itself, increasing with Spirit Level.",
          type: AbilityType.onHit,
        );

  double getProcChance(Player player) {
    int spiritLevel = PlayerProgressManager.getSpiritLevel();
    double chance = (BASE_PROC_CHANCE + (spiritLevel * 0.01)).clamp(0, 1);

    print(
        '🎲 Cursed Echo base chance: ${(BASE_PROC_CHANCE * 100).toStringAsFixed(1)}%');
    print('🌟 Spirit Level bonus: +${(spiritLevel).toStringAsFixed(1)}%');
    print('✨ Final proc chance: ${(chance * 100).toStringAsFixed(1)}%');

    return chance;
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    if (player.hasEffect('NoAttacks')) return; // Skip if attacks are disabled

    double currentTime = player.gameRef.currentTime();
    double timeSinceLastProc = currentTime - _lastProcTime;

    if (timeSinceLastProc < PROC_COOLDOWN) {
      print(
          "❌ Cursed Echo on cooldown (${(PROC_COOLDOWN - timeSinceLastProc).toStringAsFixed(2)}s remaining)");
      return;
    }

    double procChance = getProcChance(player);
    double roll = player.gameRef.random.nextDouble();

    if (roll < procChance) {
      _lastProcTime = currentTime;

      Future.delayed(Duration(milliseconds: 100), () {
        if (target.isMounted && target is BaseEnemy) {
          double spiritMultiplier = PlayerProgressManager.getSpiritMultiplier();
          int echoDamage = (damage * spiritMultiplier).toInt();

          // Mark as echoed damage to prevent XP gain
          target.takeDamage(echoDamage.toDouble(),
              isCritical: isCritical, isEchoed: true // This prevents XP gain
              );

          print(
              '🔥 Cursed Echo dealt $echoDamage damage (Crit: $isCritical) - No XP awarded');
        }
      });
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
        double spiritMultiplier = PlayerProgressManager.getSpiritMultiplier();
        double damage = (10.0 * spiritMultiplier).clamp(1.0, 9999.0);
        print(
            "💥 Explosion damage: ${damage.toStringAsFixed(1)} (${spiritMultiplier.toStringAsFixed(1)}x multiplier)");
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

class BasicAttack extends Ability {
  final DamageTracker damageTracker;

  BasicAttack()
      : damageTracker = DamageTracker("Basic Attack"),
        super(
          name: 'Basic Attack',
          description: 'Your standard projectile attack',
          type: AbilityType.projectile,
        ) {
    // Initialize the damage tracker
    DamageTracker.initialize();
    print('🎯 BasicAttack initialized with damage tracker');
  }

  @override
  void onUpdate(Player player, double dt) {
    // Basic attack is handled directly in Player's update method
  }

  @override
  void trigger(Player player) {
    // Basic attack is automatic
  }
}
