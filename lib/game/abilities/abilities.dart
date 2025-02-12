import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
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
class ShadowBladesAbility extends Ability {
  double cooldown = 0.5; // Time between blade throws
  double elapsedTime = 0.0;

  ShadowBladesAbility()
      : super(
          name: "Shadow Blades",
          description: "Throws a spectral blade at the closest enemy.",
          type: AbilityType.projectile,
        );

  void _spawnBlade(Player player) {
    BaseEnemy? target = _findClosestTarget(player);
    if (target == null) return;

    Vector2 direction = (target.position - player.position).normalized();
    double rotationAngle = direction.angleTo(Vector2(1, 0));

    final blade = ShadowBladeProjectile(
      player: player,
      damage: (12 * player.spiritMultiplier).toInt(),
      velocity: direction * 750,
      rotationAngle: rotationAngle,
      ability: this,
    )..position = player.position.clone();

    player.gameRef.add(blade);

    // Roll Cursed Echo ONCE per blade thrown
    if (player.hasAbility<CursedEcho>() &&
        player.gameRef.random.nextDouble() < 0.20) {
      print("🔄 Cursed Echo triggered for Shadow Blade!");
      Future.delayed(Duration(milliseconds: 100), () {
        player.gameRef.add(ShadowBladeProjectile(
          player: player,
          damage: (12 * player.spiritMultiplier).toInt(),
          velocity: direction * 750,
          rotationAngle: rotationAngle,
          ability: this,
        )..position = player.position.clone());
      });
    }
  }

  BaseEnemy? _findClosestTarget(Player player) {
    final enemies = player.gameRef.children.whereType<BaseEnemy>().toList();
    if (enemies.isEmpty) return null;

    BaseEnemy? closest;
    double closestDistance = double.infinity;
    for (final enemy in enemies) {
      double distance = (enemy.position - player.position).length;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = enemy;
      }
    }
    return closest;
  }

  @override
  void onUpdate(Player player, double dt) {
    elapsedTime += dt;
    if (elapsedTime >= cooldown) {
      elapsedTime = 0.0;
      _spawnBlade(player);
    }
  }
}

/// 🗡️ **Shadow Blade Projectile Component**
class ShadowBladeProjectile extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<RogueShooterGame> {
  final Player player;
  final ShadowBladesAbility ability;
  final double bladeSpeed = 750;
  double maxDistance = 1200;
  Vector2 startPosition = Vector2.zero();
  final Vector2 velocity;
  final double rotationAngle;
  final int damage;
  final DamageReport damageReport;

  ShadowBladeProjectile({
    required this.player,
    required this.velocity,
    required this.rotationAngle,
    required this.damage,
    required this.ability,
  })  : damageReport = DamageReport("Shadow Blades"),
        super(size: Vector2(48, 16), anchor: Anchor.center) {
    angle = rotationAngle;
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      await gameRef.images.load('shadowblades.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2(48, 16),
        loop: true,
      ),
    );
    startPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if ((position - startPosition).length >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BaseEnemy) {
      bool isCritical = gameRef.random.nextDouble() < (player.critChance / 100);
      int finalDamage =
          isCritical ? (damage * player.critMultiplier).toInt() : damage;

      other.takeDamage(finalDamage, isCritical: isCritical);
      ability.damageReport.recordHit(finalDamage, isCritical);
    } else if (other is Projectile && other is! ShadowBladeProjectile) {
      return;
    }

    super.onCollision(intersectionPoints, other);
  }
}

/// 🔁 **Cursed Echo Ability** - Chance to repeat attacks
class CursedEcho extends Ability {
  double baseProcChance = 0.2; // 20% base chance
  double delayBetweenRepeats = 0.2; // Delay before repeating attack
  double procCooldown = 1.0; // Cooldown to prevent excessive procs
  double _lastProcTime = 0.0;

  CursedEcho()
      : super(
          name: "Cursed Echo",
          description:
              "Every attack has a chance to repeat itself, increasing with Spirit Level.",
          type: AbilityType.onHit,
        );

  double getProcChance(Player player) {
    return (baseProcChance + (player.spiritLevel * 0.01)).clamp(0, 1);
  }

  @override
  void onHit(Player player, PositionComponent target, int damage,
      {bool isCritical = false}) {
    double currentTime = player.gameRef.currentTime();
    if (currentTime - _lastProcTime < procCooldown) return;

    if (player.gameRef.random.nextDouble() < getProcChance(player)) {
      _lastProcTime = currentTime;

      // Debug print for proc
      print(
          "🔁 Cursed Echo triggered with ${(getProcChance(player) * 100).toStringAsFixed(1)}% chance");

      Future.delayed(
          Duration(milliseconds: (delayBetweenRepeats * 1000).toInt()), () {
        if (target.isMounted) {
          // Record the echoed hit
          damageReport.recordHit(damage, isCritical);

          print("🔁 Cursed Echo dealt $damage damage (Crit: $isCritical)");

          // Apply the damage
          if (target is BaseEnemy) {
            target.takeDamage(damage, isCritical: isCritical);
          }
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
