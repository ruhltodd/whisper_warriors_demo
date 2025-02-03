import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'experience.dart';
import 'powerup.dart';
import 'main.dart';
import 'player.dart';
import 'abilitybar.dart';

class HUD extends StatelessWidget {
  final void Function(Vector2 delta) onJoystickMove;
  final ExperienceBar experienceBar;
  final RogueShooterGame game; // ✅ Reference to game for timer

  HUD({
    required this.onJoystickMove,
    required this.experienceBar,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top; // Detect notch

    return Stack(
      children: [
        // ⏳ Game Timer (Top Right)
        Positioned(
          top: safeTop + 10,
          right: 20,
          child: ValueListenableBuilder<int>(
            valueListenable: game.gameHudNotifier, // ✅ Timer updates here
            builder: (context, time, _) {
              return Text(
                game.formatTime(time), // ✅ Live updating countdown
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MyCustomFont'),
              );
            },
          ),
        ),

        // Experience Bar (Top Center)
        Positioned(
          top: safeTop + 10, // Moves it below the notch
          left: MediaQuery.of(context).size.width / 2 - 100, // Centered
          child: SizedBox(
            width: 200,
            height: 20,
            child: CustomPaint(
              painter: ExperienceBarPainter(experienceBar),
            ),
          ),
        ),

        // 🔥 Ability Bar (Top Left)
        Positioned(
          top: safeTop + 10,
          left: 10,
          child: AbilityBar(player: game.player),
        ),

        // Joystick (Bottom Left)
        Align(
          alignment: Alignment.bottomLeft,
          child: JoystickOverlay(onMove: onJoystickMove),
        ),
      ],
    );
  }
}

class JoystickOverlay extends StatefulWidget {
  final void Function(Vector2 delta) onMove;

  JoystickOverlay({required this.onMove});

  @override
  _JoystickOverlayState createState() => _JoystickOverlayState();
}

class _JoystickOverlayState extends State<JoystickOverlay> {
  Vector2 knobPosition = Vector2.zero();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final newDelta = Vector2(
          details.localPosition.dx - 50, // Offset from center
          details.localPosition.dy - 50,
        );

        if (newDelta.length > 50.0) {
          newDelta.normalize();
          newDelta.scale(50.0);
        }

        widget.onMove(newDelta);

        setState(() {
          knobPosition = newDelta;
        });
      },
      onPanEnd: (_) {
        widget.onMove(Vector2.zero());

        setState(() {
          knobPosition = Vector2.zero();
        });
      },
      child: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: JoystickPainter(knobPosition),
        ),
      ),
    );
  }
}

class JoystickPainter extends CustomPainter {
  final Vector2 knobPosition;

  JoystickPainter(this.knobPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black38;
    canvas.drawCircle(size.center(Offset.zero), 50, paint);

    final knobPaint = Paint()..color = Colors.grey;
    canvas.drawCircle(
      Offset(
        size.width / 2 + knobPosition.x,
        size.height / 2 + knobPosition.y,
      ),
      15,
      knobPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ExperienceBarOverlay extends StatelessWidget {
  final ExperienceBar experienceBar;

  ExperienceBarOverlay({required this.experienceBar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: experienceBar.barWidth,
        height: experienceBar.barHeight,
        child: CustomPaint(
          painter: ExperienceBarPainter(experienceBar),
        ),
      ),
    );
  }
}

class ExperienceBarPainter extends CustomPainter {
  final ExperienceBar experienceBar;

  ExperienceBarPainter(this.experienceBar);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black26;
    final progressPaint = Paint()
      ..color = const Color.fromARGB(255, 175, 76, 152);
    final textPaint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw background bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw progress bar
    final progressWidth =
        (experienceBar.currentExp / experienceBar.expToLevel) * size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      progressPaint,
    );
    // Draw Level Text
    final textSpan = TextSpan(
      text: "Spirit Level ${experienceBar.playerLevel}",
      style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'MyCustomFont'),
    );

    textPaint.text = textSpan;
    textPaint.layout(minWidth: size.width, maxWidth: size.width);

    final textOffset = Offset(
      (size.width - textPaint.width) / 2,
      (size.height - textPaint.height) / 2,
    );

    textPaint.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PowerUpSelectionOverlay extends StatelessWidget {
  final RogueShooterGame game;

  PowerUpSelectionOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    List<PowerUpType> options = game.powerUpOptions;

    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose a Power-Up!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: options.map((type) {
                int currentLevel = game.player.powerUpLevels[type] ?? 0;
// Get power-up level
                int nextLevel =
                    (currentLevel + 1).clamp(1, 6); // ✅ Show NEXT level

                return ElevatedButton.icon(
                  onPressed: () {
                    //  game.selectPowerUp(type);
                    game.overlays.remove('powerUpSelection');
                    game.overlays.add('powerUpBuffs'); // Update buff UI
                  },
                  icon: Icon(_getPowerUpIcon(type),
                      size: 24, color: Colors.white),
                  label: Text(
                    "${_getPowerUpName(type)} (Lvl $nextLevel)", // ✅ Show next level
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPowerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.vampiricTouch:
        return Icons.favorite;
      case PowerUpType.armorUpgrade:
        return Icons.shield;
      case PowerUpType.magnetism:
        return Icons.autorenew;
      case PowerUpType.blackHole:
        return Icons.circle;
      case PowerUpType.attackSpeedBoost: // ✅ New Icon
        return Icons.flash_on;
      case PowerUpType.movementSpeedBoost: // ✅ New Icon
        return Icons.directions_run;
      default:
        return Icons.help_outline;
    }
  }

  String _getPowerUpName(PowerUpType type) {
    switch (type) {
      case PowerUpType.vampiricTouch:
        return "Vampiric Touch";
      case PowerUpType.armorUpgrade:
        return "Armor Upgrade";
      case PowerUpType.magnetism:
        return "Magnetism";
      case PowerUpType.blackHole:
        return "Black Hole";
      case PowerUpType.attackSpeedBoost: // ✅ New Name
        return "Attack Speed";
      case PowerUpType.movementSpeedBoost: // ✅
      default:
        return "Unknown Power";
    }
  }
}

class PowerUpBuffsOverlay extends StatelessWidget {
  final RogueShooterGame game;

  PowerUpBuffsOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: Row(
        children: game.player.activePowerUps.entries.map((entry) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Power-up icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.7), // Dark background
                ),
                child: Icon(
                  _getPowerUpIcon(entry.key),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              // Level number overlay
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent, // Background for level number
                  ),
                  child: Center(
                    child: Text(
                      "${entry.value}", // Display power-up level
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _getPowerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.vampiricTouch:
        return Icons.favorite; // Heart for healing
      case PowerUpType.armorUpgrade:
        return Icons.shield;
      case PowerUpType.magnetism:
        return Icons.autorenew; // Magnet for item pull
      case PowerUpType.blackHole:
        return Icons.circle; // Placeholder for black hole
      default:
        return Icons.help_outline;
    }
  }
}
