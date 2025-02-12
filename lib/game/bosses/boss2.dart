import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/bosses/staggerbar.dart';
import 'package:whisper_warriors/game/inventory/loottable.dart';
import 'package:whisper_warriors/game/items/lootbox.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/ai/enemy.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
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

  double elapsedTime = 0.0;
  static const double oscillationDuration = 10.0;
  double rotationDirection = 1.0; // ✅ 1 for normal, -1 for reverse
  List<LaserBeam> beams = [];

  LaserWheel({
    required this.bossPosition,
    this.numberOfBeams = 6,
    this.beamLength = 1000,
    this.beamWidth = 4,
    this.damagePerSecond = 1,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    double angleStep = (2 * pi) / numberOfBeams;

    for (int i = 0; i < numberOfBeams; i++) {
      double angle = i * angleStep;

      final beam = LaserBeam(
        startPosition: bossPosition.clone(),
        length: beamLength,
        width: beamWidth,
        damagePerSecond: damagePerSecond,
        initialAngle: angle,
      );

      beams.add(beam);
      gameRef.add(beam);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    elapsedTime += dt;

    // ✅ Reverse direction every 3 seconds
    if (elapsedTime >= oscillationDuration) {
      rotationDirection *= -1; // 🔄 Reverse the movement
      elapsedTime = 0.0;
    }

    double rotationSpeed = pi / 16;
    for (var beam in beams) {
      beam.angle += rotationSpeed * rotationDirection * dt;
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
        gameRef.player.takeDamage(damagePerSecond.toInt());
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
  late StaggerBar staggerBar;
  final Random random = Random();
  final ValueNotifier<double> bossStaggerNotifier;
  int attackCount = 0;
  bool alternatePattern = false;

  Boss2({
    required Player player,
    required int health,
    required double speed,
    required Vector2 size,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onStaggerChanged,
    required this.bossStaggerNotifier,
  }) : super(
          player: player,
          health: health,
          speed: speed,
          size: size,
        ) {
    maxHealth = health.toDouble();
    staggerBar = StaggerBar(maxStagger: 100.0, currentStagger: 0);
  }

  @override
  Future<void> onLoad() async {
    gameRef.setActiveBoss("Void Prism", 80000);
    idleAnimation = await gameRef.loadSpriteAnimation(
      'boss2.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: Vector2(256, 256),
        stepTime: 0.6,
      ),
    );

    attackAnimation = await gameRef.loadSpriteAnimation(
      'boss2.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(256, 256),
        stepTime: 0.3,
      ),
    );
    animation = idleAnimation;
    add(RectangleHitbox());
    gameRef.add(staggerBar);
  }

  void updateStaggerBar() {
    staggerBar.currentStagger = staggerProgress;
    bossStaggerNotifier.value = staggerProgress;
  }

  void update(double dt) {
    super.update(dt);
    updateStagger(dt);
    updateStaggerBar();

    if (isStaggered) return;

    timeSinceLastAttack += dt;
    timeSinceLastDamageNumber += dt;

    _updateMovement(dt);
    _handleAttacks(dt);
  }

// boss2 doesn't move, so we can remove the walkAnimation and _updateMovement method
  void _updateMovement(double dt) {
    animation = (player.position - position).length < 10
        ? attackAnimation
        : idleAnimation;
    if ((player.position - position).length < 10) {
      player.takeDamage(10);
    }
  }

  void _handleAttacks(double dt) {
    timeSinceLastAttack += dt;
    if (timeSinceLastAttack >= attackCooldown) {
      _activateLaserBeam();
      timeSinceLastAttack = 0.0;
    }
  }

  void _activateLaserBeam() {
    // ✅ Ensure only ONE LaserWheel exists at a time
    if (gameRef.children.whereType<LaserWheel>().isNotEmpty) {
      print("⚠️ LaserWheel already exists, skipping spawn.");
      return;
    }

    print("🚀 Spawning LaserWheel!");
    gameRef.add(LaserWheel(bossPosition: position));
  }

  @override
  void takeDamage(int baseDamage, {bool isCritical = false}) {
    if (!isCritical) {
      isCritical = gameRef.random.nextDouble() < player.critChance / 100;
    }
    int finalDamage =
        isCritical ? (baseDamage * player.critMultiplier).toInt() : baseDamage;
    health -= finalDamage;
    onHealthChanged(health.toDouble());
    applyStaggerDamage(finalDamage, isCritical: isCritical); //stagger update

    if (health <= (maxHealth * 0.3) && !enraged) {
      enraged = true;
      _enterEnrageMode();
    }
    if (health <= 0) {
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
    if (!hasDroppedItem) {
      hasDroppedItem = true;
      final dropItems = _getDropItems();
      final lootBox =
          LootBox(items: dropItems.map((dropItem) => dropItem.item).toList());
      lootBox.position = position.clone();
      gameRef.add(lootBox);
      print("🗃️ LootBox spawned at position: ${lootBox.position}");
    }

    // ✅ Remove all laser beams from the game when the boss dies
    for (var laser in gameRef.children.whereType<LaserBeam>()) {
      laser.removeFromParent();
    }
    print("🛑 All laser beams removed!");

    onDeath();
    gameRef.add(Explosion(position));
    removeFromParent(); // ✅ Boss is removed from the game world
  }

  List<DropItem> _getDropItems() {
    final List<DropItem> dropItems = [];

    // Add the gold coin
    dropItems.add(DropItem(item: GoldCoin()));

    // Add the random loot item
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
}
