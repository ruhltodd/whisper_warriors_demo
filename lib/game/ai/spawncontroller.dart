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

class SpawnController extends Component {
  final RogueShooterGame game;
  late TimerComponent enemySpawnerTimer;
  bool _bossActive = false;
  int enemyCount = 0;
  int elapsedTime = 0;
  bool _isSpawning = true;

  SpawnController({required this.game});

  @override
  Future<void> onLoad() async {
    _startEnemyWaves();
  }

  /// ✅ **Start enemy waves every 10 seconds**
  /// ✅ **Start enemy waves every 10 seconds**
  void _startEnemyWaves() {
    Future.delayed(Duration(seconds: 2), () {
      if (_bossActive) {
        return; // ✅ Prevents any spawn if Boss1 or Boss2 is active
      }
      spawnEnemyWave(10);
    });

    enemySpawnerTimer = TimerComponent(
      period: 5, // ✅ Every 5 seconds
      repeat: true,
      onTick: () {
        if (_bossActive) {
          return; // ✅ Fully stops any spawning if Boss1 or Boss2 is active
        }
        spawnEnemyWave(15);
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

  void decreaseEnemyCount() {
    enemyCount = (enemyCount - 1).clamp(0, 50); // ✅ Prevents negative values
  }

  /// ✅ **Clear all remaining enemies**
  void _clearEnemyWaves() {
    for (var enemy in game.children.whereType<BaseEnemy>()) {
      enemy.removeFromParent();
    }
    enemyCount = 0; // ✅ **Ensure count resets when clearing**
  }

  void stopSpawning() {
    _isSpawning = false;
  }

  void spawnEnemyWave(int count, {bool postBoss = false}) {
    int availableSlots = 50 - enemyCount;
    if (availableSlots <= 0) {
      return;
    }

    int spawnAmount = count > availableSlots ? availableSlots : count;

    for (int i = 0; i < spawnAmount; i++) {
      final spawnPosition = _getRandomSpawnPosition();

      BaseEnemy enemy;

      int baseHealth = 3000; // Default health
      double baseSpeed = 50; // Default Speed

      if (game.elapsedTime >= 60) {
        if (Random().nextBool()) {
          enemy = Wave2Enemy(
            player: game.player,
            speed: baseSpeed = 90,
            health: baseHealth = 500,
            size: Vector2(84, 84),
          );
        } else {
          enemy = Wave1Enemy(
            player: game.player,
            speed: baseSpeed,
            health: baseHealth,
            size: Vector2(64, 64),
          );
        }
      } else {
        enemy = Wave1Enemy(
          player: game.player,
          speed: baseSpeed,
          health: baseHealth,
          size: Vector2(64, 64),
        );
      }

      // ✅ **Enhance Enemies After Boss Fight**
      if (postBoss) {
        baseHealth *= 2;
        baseSpeed *= 0.5;
      }

      // ✅ **Ensure enemies are removed from count**
      enemy.onRemoveCallback = () {
        game.spawnController?.decreaseEnemyCount();
      };

      enemy.position = spawnPosition; // ✅ Set position FIRST
      if (enemyCount < 50) {
        enemyCount++;
        game.add(enemy);
      } else {}
    }
  }
  //      enemy.position = spawnPosition;

  Vector2 _getRandomSpawnPosition() {
    final random = Random();
    final spawnMargin = 50.0; // Margin around the spawn edge
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
    } while ((spawnPosition - game.player.position).length <
        256.0); // Ensure spawn is at least 256 pixels away from the player

    return spawnPosition;
  }

  void _postBossEnemySpawn() {
    enemySpawnerTimer = TimerComponent(
      period: 4.0, // ✅ Faster spawn rate after boss
      repeat: true,
      onTick: () {
        if (_bossActive) {
          // ✅ Stop spawns if any boss is active
          return;
        }
        spawnEnemyWave(12, postBoss: true); // ✅ More enemies
      },
    );

    game.add(enemySpawnerTimer);
  }

  void _triggerBossImpactEffect(Vector2 position) {
    print("💥 Boss slammed into the ground!");
    add(Explosion(position)); // ✅ Explosion at impact location
  }

  void checkAndTriggerEvents(int currentTime) {
    // Add debug logging
    if (currentTime >= 100 && currentTime <= 115) {}

    // Only spawn Boss1 at 60 seconds if no boss is active
    if (currentTime == 60 && !_bossActive) {
      spawnBoss1();
    }
  }

  /// ✅ **After Boss 2 Dies - Stop all enemy waves**
  void onBoss2Death() {
    print("💀 Void Prism has been defeated!");
    game.bossHealthNotifier.value = 1.0;
    _bossActive = false; // ✅ Now enemies can spawn again

    Future.delayed(Duration(seconds: 3), () {
      if (!_bossActive) {
        // ✅ Ensure no boss is active before restarting
        print("🔄 Restarting enemy waves after Boss2 death.");
        _startEnemyWaves();
      }
    });
  }

  /// ✅ **Spawn Boss 2 (Void Prism)**
  void spawnBoss2() {
    print("⚔️ Void Prism is preparing to enter the battlefield!");
    _bossActive = true;
    _isSpawning = false; // ✅ Stop enemy spawning
    _stopEnemySpawns();

    // ✅ **Make sure no enemies spawn again**
    if (enemySpawnerTimer.isMounted) {
      game.remove(enemySpawnerTimer);
      print("🛑 Enemy spawner removed!");
    }

    // ✅ **Clear enemies & add a delay**
    _clearEnemyWaves();
    Future.delayed(Duration(seconds: 2), () {
      print("💨 All enemy waves cleared! Boss 2 now spawning...");

      final boss2 = Boss2(
        player: game.player,
        health: 160000,
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
      game.setActiveBoss("Void Prism", 160000);

      print("⚔️ Boss 2 (Void Prism) has entered the battlefield!");
    });
  }

  /// ✅ **After Boss 1 Dies - Resume Enemy Waves**
  void onBoss1Death() {
    print("👹 Boss 1 defeated! Starting post-boss sequence");
    game.bossHealthNotifier.value = 1.0;
    _bossActive = false;

    // ✅ **Spawn tougher enemies before Boss 2 arrives**
    _postBossEnemySpawn();

    // ✅ **Schedule Boss 2 after exactly 1 minute**
    Future.delayed(Duration(seconds: 60), () {
      if (!_bossActive) {
        // Double check boss isn't active
        print("⏰ One minute passed after Boss 1's death, spawning Boss 2");
        spawnBoss2();
      }
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
      health: 211000,
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
    game.setActiveBoss("Umbrathos, The Fading King", 211000);

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
