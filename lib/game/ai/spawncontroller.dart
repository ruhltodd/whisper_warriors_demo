import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/ai/wave1Enemy.dart';
import 'package:whisper_warriors/game/ai/wave2Enemy.dart';
import 'package:whisper_warriors/game/bosses/boss1.dart';
import 'package:whisper_warriors/game/bosses/boss2.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/player/player.dart';

class SpawnController extends Component {
  final RogueShooterGame game;
  late TimerComponent enemySpawnerTimer;
  bool _bossActive = false;
  int enemyCount = 0;
  int elapsedTime = 0;
  bool _boss2Active = false;
  bool _isSpawning = true;

  SpawnController({required this.game});

  @override
  Future<void> onLoad() async {
    _startEnemyWaves();
  }

  /// ✅ **Start enemy waves every 10 seconds**
  void _startEnemyWaves() {
    // ✅ Spawn enemies immediately when the game starts
    Future.delayed(Duration(seconds: 2), () {
      spawnEnemyWave(10); // ✅ First wave spawns after delay
    });

    enemySpawnerTimer = TimerComponent(
      period: 5, // ✅ Every 10 seconds
      repeat: true,
      onTick: () {
        if (!_bossActive && !_boss2Active) {
          spawnEnemyWave(15);
        }
      },
    );
    game.add(enemySpawnerTimer);
  }

  /// ✅ **Stop enemy spawning completely**
  void _stopEnemySpawns() {
    if (enemySpawnerTimer.isMounted) {
      game.remove(enemySpawnerTimer);
    }
  }

  /// ✅ **Clear all remaining enemies**
  void _clearEnemyWaves() {
    print("💨 Clearing all remaining enemies...");

    final enemies = game.children.whereType<BaseEnemy>().toList();

    for (var enemy in enemies) {
      print("❌ Removing ${enemy.runtimeType} at ${enemy.position}");
      enemy.removeFromParent(); // ✅ Removes each enemy
    }

    print("✅ All enemies removed before Boss2.");
  }

  void stopSpawning() {
    _isSpawning = false;
  }

  void spawnEnemyWave(int count, {bool postBoss = false}) {
    print("🔥 Spawning $count enemies. postBoss = $postBoss");

    for (int i = 0; i < count; i++) {
      final spawnPosition = _getRandomSpawnPosition();
      print("🚀 Enemy spawn position: $spawnPosition");

      BaseEnemy enemy;

      // ✅ Post-Boss logic should **increase Wave2Enemy probability**
      if (postBoss) {
        if (i % 2 == 0) {
          print("👾 Post-Boss: Spawning Wave1Enemy...");
          enemy = Wave1Enemy(
            player: game.player,
            speed: 80, // Slightly increased speed post-boss
            health: 300, // More health after boss
            size: Vector2(64, 64),
          );
        } else {
          print("🔥 Post-Boss: Spawning Wave2Enemy...");
          enemy = Wave2Enemy(
            player: game.player,
            speed: 100, // Faster than Wave1Enemy
            health: 600, // More tanky than Wave1Enemy
            size: Vector2(128, 128),
          );
        }
      } else {
        // ✅ **Pre-Boss Enemy Logic**
        if (elapsedTime >= 60) {
          // ✅ Before Boss1: **Mix Wave1 & Wave2**
          if (i % 2 == 0) {
            print("👾 Spawning Wave1Enemy...");
            enemy = Wave1Enemy(
              player: game.player,
              speed: 70,
              health: 200,
              size: Vector2(64, 64),
            );
          } else {
            print("🔥 Spawning Wave2Enemy...");
            enemy = Wave2Enemy(
              player: game.player,
              speed: 90,
              health: 500,
              size: Vector2(128, 128),
            );
          }
        } else {
          // ✅ **Before 60 seconds, only Wave1Enemy**
          print("👾 Pre-Boss: Spawning Wave1Enemy...");
          enemy = Wave1Enemy(
            player: game.player,
            speed: 70,
            health: 100,
            size: Vector2(64, 64),
          );
        }
      }

      // ✅ **Enhance Enemies After Boss Fight**
      if (postBoss) {
        print("⚡ Post-Boss Scaling: Boosting enemy stats!");
        enemy.health *= 2; // 🔥 Double Health
        enemy.speed *= 0.1; // 🔥 Slightly Faster
      }

      enemy.position = spawnPosition; // ✅ Ensure it's placed correctly
      enemy.onRemoveCallback = () {
        enemyCount--;
        print("⚠️ Enemy Removed: ${enemy.runtimeType}");
      };

      enemyCount++;
      game.add(enemy);
      print("✅ Enemy added: ${enemy.runtimeType} at $spawnPosition");
    }
  }

  Vector2 _getRandomSpawnPosition() {
    final random = Random();
    final spawnMargin = 50.0;
    Vector2 spawnPosition;

    do {
      final side = random.nextInt(4);
      switch (side) {
        case 0:
          spawnPosition =
              Vector2(random.nextDouble() * game.size.x, -spawnMargin);
          break;
        case 1:
          spawnPosition = Vector2(
              game.size.x + spawnMargin, random.nextDouble() * game.size.y);
          break;
        case 2:
          spawnPosition = Vector2(
              random.nextDouble() * game.size.x, game.size.y + spawnMargin);
          break;
        case 3:
          spawnPosition =
              Vector2(-spawnMargin, random.nextDouble() * game.size.y);
          break;
        default:
          spawnPosition = Vector2.zero();
      }
    } while ((spawnPosition - game.player.position).length < 100.0);

    return spawnPosition;
  }

  void _postBossEnemySpawn() {
    print("🔥 Post-boss enemies now spawning!");

    // ✅ Resume enemy spawner with a **faster rate & tougher enemies**
    enemySpawnerTimer = TimerComponent(
      period: 4.0, // ✅ Faster spawn rate after boss
      repeat: true,
      onTick: () => spawnEnemyWave(12, postBoss: true), // ✅ More enemies
    );
    game.add(enemySpawnerTimer);
  }

  void _triggerBossImpactEffect(Vector2 position) {
    print("💥 Boss slammed into the ground!");
    add(Explosion(position)); // ✅ Explosion at impact location
  }

  void checkAndTriggerEvents(int elapsedTime) {
    print(
        "🕒 Time: $elapsedTime - Boss Active: $_bossActive - Boss2 Active: $_boss2Active");

    if (elapsedTime == 60 && !_bossActive) {
      print("🔥 Spawning Boss1...");
      spawnBoss1();
    }
  }

  /// ✅ **After Boss 2 Dies - Stop all enemy waves**
  void onBoss2Death() {
    print("💀 Void Prism has been defeated!");
    game.bossHealthNotifier.value = null;
    _boss2Active = false;
  }

  /// ✅ **Spawn Boss 2 (Void Prism)**
  void spawnBoss2() {
    print("⚔️ Void Prism has entered the battlefield!");
    _boss2Active = true;
    _stopEnemySpawns();

    Future.delayed(Duration(milliseconds: 500), () {
      _clearEnemyWaves(); // ✅ Ensure all enemies are removed after a short delay
    });

    final boss2 = Boss2(
      player: game.player,
      health: 60000,
      speed: 0,
      size: Vector2(256, 256),
      onHealthChanged: (double health) =>
          game.bossHealthNotifier.value = health,
      onDeath: () => onBoss2Death(),
      onStaggerChanged: (double stagger) =>
          game.bossStaggerNotifier.value = stagger,
      bossStaggerNotifier: game.bossStaggerNotifier,
    );

    boss2.position = Vector2(1280 / 2, 1280 / 2);
    game.add(boss2);
    game.setActiveBoss("Void Prism", 60000);
  }

  /// ✅ **After Boss 1 Dies - Resume Enemy Waves**
  void onBoss1Death() {
    print("👹 Resuming enemy waves after Boss 1");
    game.bossHealthNotifier.value = null;
    _bossActive = false;

    // ✅ **Spawn tougher enemies before Boss 2 arrives**
    _postBossEnemySpawn();

    // ✅ **Schedule Boss 2 after 1 min**
    Future.delayed(Duration(seconds: 60), () {
      spawnBoss2();
    });
  }

  /// ✅ **Spawn Boss 1 at 60s**
  void spawnBoss1() {
    print("⚔️ Boss 1 is entering the battlefield!");
    _bossActive = true;
    _stopEnemySpawns();
    _clearEnemyWaves();

    // ✅ Create boss instance **off-screen**
    final boss1 = Boss1(
      player: game.player,
      speed: 20,
      health: 5000,
      size: Vector2(128, 128),
      onHealthChanged: (double health) {
        game.bossHealthNotifier.value = health; // ✅ Ensure UI updates
      },
      onDeath: () => onBoss1Death(),
      onStaggerChanged: (double stagger) =>
          game.bossStaggerNotifier.value = stagger,
      bossStaggerNotifier: game.bossStaggerNotifier,
    );

    // ✅ **Spawn boss off-screen (above map)**
    boss1.position = Vector2(game.size.x / 2, -300);
    boss1.anchor = Anchor.center;
    game.add(boss1);

    // ✅ **Set active boss in HUD**
    game.setActiveBoss("Umbrathos, The Fading King", 50000);

    // ✅ **Delayed movement into battlefield**
    Future.delayed(Duration(milliseconds: 1500), () {
      print(
          "Before moving: ${boss1.position}"); // ✅ Debugging Position Before Moving

      boss1.position = Vector2(1280 / 2, 1280 / 2);
      boss1.anchor = Anchor.center; // ✅ Ensure anchor is centered

      print(
          "After moving: ${boss1.position}"); // ✅ Debugging Position After Moving

      // ✅ Apply screen shake
      game.shakeScreen(game.customCamera);
      _triggerBossImpactEffect(boss1.position);
    });
  }
}
