import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/explosion.dart';
import 'package:whisper_warriors/game/utils/dropitem.dart';
import 'staggerable.dart';

/// The LaserBeam class represents a laser beam component in the game.
/// It is used to create laser beams that rotate and deal damage to the player
/// if they are in the path of the beam. The beams can be spawned in a circular
/// pattern around a boss character and can alternate their rotation direction.
class LaserWheel extends Component with HasGameRef<RogueShooterGame> {
  final Vector2 bossPosition;
  final int numberOfBeams;
  final double beamLength;
  final double beamWidth;
  final double damagePerSecond;
  final VoidCallback onLaserWheelRemove; // Callback to reset the flag
  double elapsedTime = 0.0;
  List<LaserBeam> beams = [];
  double attackDuration = 10.0; // ✅ Duration of the laser attack in seconds
  double rotationSpeed = pi / 8; // Rotation speed in radians per second

  LaserWheel({
    required this.bossPosition,
    required this.onLaserWheelRemove,
    this.numberOfBeams = 6,
    this.beamLength = 1000,
    this.beamWidth = 4,
    this.damagePerSecond = 1,
  });
  @override
  Future<void> onLoad() async {
    super.onLoad();
    double angleStep = (2 * pi) / numberOfBeams;

    // Create all beams first
    beams = List.generate(numberOfBeams, (i) {
      double angle = i * angleStep;
      return LaserBeam(
        startPosition: bossPosition.clone(),
        length: beamLength,
        width: beamWidth,
        damagePerSecond: damagePerSecond,
        initialAngle: angle,
      );
    });

    // Add all beams to the game at once
    gameRef.addAll(beams);
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsedTime += dt;

    double angleStep = (2 * pi) / numberOfBeams;
    for (int i = 0; i < beams.length; i++) {
      double currentAngle = i * angleStep + elapsedTime * rotationSpeed;
      beams[i].updatePosition(bossPosition, currentAngle);
    }
    // ✅ Check if the attack duration has been reached
    if (elapsedTime >= attackDuration) {
      // Remove all beams from the game
      for (var beam in beams) {
        beam.removeFromParent();
      }
      beams.clear();
      // Remove this component as well
      removeFromParent();
      onLaserWheelRemove(); // Call the callback to reset the flag
      return;
    }
  }
}

class LaserBeam extends PositionComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  final Vector2 startPosition;
  final double length;
  final double width;
  final double damagePerSecond;
  final double initialAngle;
  double timeSinceLastDamage = 0.0;

  LaserBeam({
    required this.startPosition,
    required this.length,
    required this.width,
    required this.damagePerSecond,
    required this.initialAngle,
  }) {
    position = startPosition;
    size = Vector2(length, width);
    angle = initialAngle;

    final hitboxParent = PositionComponent(
      size: Vector2(length, width),
      angle: initialAngle, // ✅ Ensures the hitbox follows the beam rotation
      anchor: Anchor.center,
    );
    hitboxParent.add(
      RectangleHitbox()
        ..size = Vector2(length, width)
        ..anchor = Anchor.center,
    );
    add(hitboxParent);
  }
  void updatePosition(Vector2 bossPosition, double newAngle) {
    // Set the position of the beam to the boss's position
    position.setFrom(bossPosition);

    // Keep the beam length constant regardless of angle
    size = Vector2(length, width);
    angle = newAngle;

    // Keep anchor at center for consistent rotation
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.redAccent, Colors.orange, Colors.yellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, length, width))
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(length, 0), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_playerInBeam()) {
      timeSinceLastDamage += dt;
      if (timeSinceLastDamage >= 1.0) {
        gameRef.player.takeDamage(damagePerSecond);
        timeSinceLastDamage = 0.0;
      }
    }
  }

  bool _playerInBeam() {
    final player = gameRef.player;
    final Vector2 beamDirection = Vector2(cos(angle), sin(angle));
    final Vector2 playerOffset = player.position - startPosition;

    bool withinRange = playerOffset.length <= length;
    bool alignedWithBeam =
        playerOffset.normalized().dot(beamDirection).abs() > 0.95;

    return withinRange && alignedWithBeam;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    print('LaserBeam collided with ${other.runtimeType}');
  }
}

class Boss2 extends BaseEnemy with Staggerable {
  bool enraged = false;
  double attackCooldown = 4.0;
  double timeSinceLastAttack = 0.0;
  final double damageNumberInterval = 0.5;
  bool hasDroppedItem = false;
  final Function(double) onHealthChanged;
  final ValueChanged<double> onStaggerChanged;
  VoidCallback onDeath;
  late final double maxHealth;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation attackAnimation;
  final Map<String, SpriteAnimation> animations = {};
  late StaggerBar staggerBar;
  final Random random = Random();
  final ValueNotifier<double> bossStaggerNotifier;
  int attackCount = 0;
  double _currentHealth;
  bool _isDying = false;
  bool _isRemoved = false;
  bool _isAttacking = false;

  Boss2({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onStaggerChanged,
    required this.bossStaggerNotifier,
  })  : _currentHealth = health.toDouble(),
        super(
          player: player,
          health: health,
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0);
  }

  double get currentHealth => _currentHealth;
  set currentHealth(double value) {
    _currentHealth = value.clamp(0, maxHealth);
    health = _currentHealth
        .toInt(); // Update base health when current health changes
    onHealthChanged(_currentHealth);
  }

  @override
  Future<void> onLoad() async {
    gameRef.setActiveBoss("Void Prism", 160000);

    final idleSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('boss2.png'),
      srcSize: Vector2(256, 256),
    );

    animations['idle'] = idleSpriteSheet.createAnimation(
      row: 0,
      stepTime: 0.3,
      from: 0,
      to: 1,
    );

    final attackSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('boss2.png'),
      srcSize: Vector2(256, 256),
    );

    animations['attack'] = attackSpriteSheet.createAnimation(
      row: 0,
      stepTime: 0.3,
      from: 2,
      to: 3,
    );

    idleAnimation = animations['idle']!;
    attackAnimation = animations['attack']!;
    add(RectangleHitbox());
    gameRef.add(staggerBar);
    _spawnLaserWheel();
  }

  void _spawnLaserWheel() {
    if (_isDying || _isRemoved) return;

    _isAttacking = true;
    gameRef.add(LaserWheel(
      bossPosition: position,
      onLaserWheelRemove: () {
        print("🛑 LaserWheel removed naturally");
        _isAttacking = false; // Reset attack state
      },
    ));
    print("🚀 Spawning LaserWheel!");
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress;
    bossStaggerNotifier.value = staggerProgress;
  }

  void _updateMovement(double dt) {
    animation = (player.position - position).length < 10
        ? attackAnimation
        : idleAnimation;
    if ((player.position - position).length < 10) {
      player.takeDamage(10);
    }
  }

  @override
  void takeDamage(double baseDamage, {bool isCritical = false}) {
    // Early return if boss is dying or removed
    if (_isDying || _isRemoved) {
      print("⚠️ Ignored damage on dying/removed boss");
      return;
    }

    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }

    double finalDamage =
        isCritical ? (baseDamage * player.critMultiplier) : baseDamage;
    currentHealth -= finalDamage;

    applyStaggerDamage(finalDamage.toInt(), isCritical: isCritical);
    print(
        "👻 Boss2 took $finalDamage damage. Health: $currentHealth / $maxHealth");

    if (currentHealth <= (maxHealth * 0.3) && !enraged) {
      enraged = true;
      _enterEnrageMode();
    }

    if (currentHealth <= 0 && !_isDying) {
      print("💀 Boss2 health reached 0, initiating death");
      die();
    }
  }

  void _enterEnrageMode() {
    speed *= 1.5;
    attackCooldown *= 0.7;

    add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.5))
      ..onComplete = () {
        add(OpacityEffect.to(
          0.7,
          EffectController(duration: 0.5),
        ));
      });
  }

  @override
  void die() {
    if (_isDying || _isRemoved) {
      print("⚠️ Attempted to kill already dying/removed boss");
      return;
    }

    _isDying = true;
    print("💀 Boss2 death sequence started");

    // Cancel any ongoing attacks
    _isAttacking = false;

    if (!hasDroppedItem) {
      hasDroppedItem = true;
      final dropItems = _getDropItems();
      final lootBox =
          LootBox(items: dropItems.map((dropItem) => dropItem.item).toList());
      lootBox.position = position.clone();
      gameRef.add(lootBox);
      print("🗃️ LootBox spawned at position: ${lootBox.position}");
    }

    // Remove all laser-related components
    gameRef.children.whereType<LaserBeam>().forEach((laser) {
      laser.removeFromParent();
      print("🔫 Removed laser beam");
    });

    gameRef.children.whereType<LaserWheel>().forEach((wheel) {
      wheel.removeFromParent();
      print("⭕ Removed laser wheel");
    });

    // Remove UI components
    staggerBar.removeFromParent();
    print("📊 Removed stagger bar");

    // Call onDeath callback
    onDeath();
    gameRef.add(Explosion(position));

    _isRemoved = true;
    removeFromParent();
    print("🎮 Boss2 completely removed from game");
  }

  @override
  void onRemove() {
    print(
        "🔄 Boss2 onRemove called. Is Dying: $_isDying, Is Removed: $_isRemoved, Is Attacking: $_isAttacking");

    if (!_isDying) {
      print("⚠️ WARNING: Boss2 removed unexpectedly!");
      // Try to clean up any remaining components
      gameRef.children
          .whereType<LaserBeam>()
          .forEach((laser) => laser.removeFromParent());
      gameRef.children
          .whereType<LaserWheel>()
          .forEach((wheel) => wheel.removeFromParent());
      staggerBar.removeFromParent();
    }

    super.onRemove();
  }

  List<DropItem> _getDropItems() {
    final List<DropItem> dropItems = [];
    dropItems.add(DropItem(item: GoldCoin()));

    final item = LootTable.getRandomLoot();
    if (item != null) {
      dropItems.add(DropItem(item: item));
    }

    return dropItems;
  }

  @override
  void applyStaggerVisuals() {
    add(ColorEffect(
      const Color(0xFFFF0000),
      EffectController(duration: 0.5, reverseDuration: 0.5),
    ));
  }

  @override
  void update(double dt) {
    if (_isDying || _isRemoved) return;

    super.update(dt);
    updateStagger(dt);
    updateStaggerBar();
    _updateMovement(dt);

    // Only spawn new laser wheel if not attacking and not dying
    if (!_isAttacking && !_isDying && !_isRemoved) {
      _spawnLaserWheel();
    }
  }
}
