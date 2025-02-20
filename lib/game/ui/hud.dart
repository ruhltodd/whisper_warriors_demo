import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:whisper_warriors/game/inventory/inventorybar.dart';
import 'package:whisper_warriors/game/ui/globalexperiencelevelbar.dart';
import 'package:whisper_warriors/game/ui/spiritlevelbar.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/abilities/abilitybar.dart';
import 'package:whisper_warriors/game/bosses/bosshealthbar.dart';
import 'package:whisper_warriors/game/bosses/staggerable.dart'; // Add this line
import 'package:whisper_warriors/game/ui/textstyles.dart'; // Add this import
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HUD extends StatelessWidget {
  final void Function(Vector2 delta) onJoystickMove;
  final SpiritBar experienceBar;
  final RogueShooterGame game;
  final ValueNotifier<double?> bossHealthNotifier;
  final ValueNotifier<double?> bossStaggerNotifier;

  HUD({
    required this.onJoystickMove,
    required this.experienceBar,
    required this.game,
    required this.bossHealthNotifier,
    required this.bossStaggerNotifier,
  });

  bool get _shouldShowJoystick {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 820,
      height: 820,
      child: Stack(
        children: [
          // 📈 XP Bar (Top Center)
          Positioned(
            top: 2,
            left: 410 - 75, // Centered: 820/2 - width/2
            child: GlobalExperienceLevelBar(smallSize: true),
          ),

          // ⚡ Spirit Bar
          Positioned(
            top: 10,
            left: 410 - 100, // Centered: 820/2 - width/2
            child: SizedBox(
              width: 200,
              height: 20,
              child: CustomPaint(
                painter: SpiritBarPainter(experienceBar),
              ),
            ),
          ),

          // ⏳ Game Timer
          Positioned(
            top: 10,
            right: 20,
            child: ValueListenableBuilder<dynamic>(
              valueListenable: game.gameHudNotifier,
              builder: (context, value, _) {
                if (value is int) {
                  return Text(
                    game.formatTime(value),
                    style: GameTextStyles.gameTitle(
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // 👑 Boss UI
          Positioned(
            top: 40,
            left: 410 - 100, // Centered: 820/2 - width/2
            child: ValueListenableBuilder<String?>(
              valueListenable: game.activeBossNameNotifier,
              builder: (context, bossName, _) {
                return ValueListenableBuilder<double?>(
                  valueListenable: bossHealthNotifier,
                  builder: (context, bossHealth, _) {
                    if (bossHealth == null ||
                        bossHealth <= 0 ||
                        bossName == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        Text(
                          bossName,
                          style: GameTextStyles.gameTitle(fontSize: 20),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 200,
                          child: BossHealthBar(
                            bossHealth: game.bossHealthNotifier,
                            maxBossHealth: game.maxBossHealth,
                            segmentSize: 1000,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 🔥 Ability Bar
          Positioned(
            top: 10,
            left: 10,
            child: AbilityBar(player: game.player),
          ),

          // 🛡️ Inventory Bar
          if (game.player.inventory.isNotEmpty)
            Positioned(
              top: 70,
              left: 10,
              child: InventoryBar(player: game.player),
            ),

          // 🎮 Joystick
          if (_shouldShowJoystick)
            Positioned(
              left: 30,
              bottom: 30,
              child: JoystickOverlay(onMove: onJoystickMove),
            ),
        ],
      ),
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

class SpiritBarOverlay extends StatelessWidget {
  final SpiritBar spiritBar; // ✅ Renamed ExperienceBar to SpiritBar

  SpiritBarOverlay({required this.spiritBar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: spiritBar.barWidth,
        height: spiritBar.barHeight,
        child: CustomPaint(
          painter: SpiritBarPainter(spiritBar), // ✅ Updated Painter
        ),
      ),
    );
  }
}

class SpiritBarPainter extends CustomPainter {
  final SpiritBar spiritBar;

  SpiritBarPainter(this.spiritBar);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // ✅ Dynamic Gradient based on Spirit Level
    final Paint progressPaint = Paint()
      ..shader = LinearGradient(
        colors: _getGradientColors(spiritBar.spiritLevel),
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final RRect backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    // ✅ Draw background
    canvas.drawRRect(backgroundRect, backgroundPaint);

    // ✅ Draw progress bar with rounded edges
    final double progressWidth =
        (spiritBar.spiritExp / spiritBar.spiritExpToNextLevel) * size.width;

    final RRect progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(progressRect, progressPaint);

    // ✅ Draw Spirit Level Text with improved visibility
    final TextSpan textSpan = TextSpan(
      text: "Spirit Level ${spiritBar.spiritLevel}",
      style: GameTextStyles.gameTitle(
        fontSize: 16,
        letterSpacing: 1.0,
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: size.width, maxWidth: size.width);

    final Offset textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// ✅ Dynamic Gradient Based on Spirit Level
  List<Color> _getGradientColors(int level) {
    if (level < 3) {
      return [Colors.redAccent, Colors.orange]; // 🔥 Low Spirit = Red-Orange
    } else if (level < 6) {
      return [Colors.yellow, Colors.green]; // 🌿 Mid Spirit = Yellow-Green
    } else {
      return [
        const Color.fromARGB(255, 255, 68, 224),
        Colors.purpleAccent
      ]; // 🔵 High Spirit = Blue-Purple
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BossHealthBarPainter extends CustomPainter {
  final double health;
  final double maxHealth;
  final String bossName;

  BossHealthBarPainter({
    required this.health,
    required this.maxHealth,
    required this.bossName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final paintHealth = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Ensure health width doesn't go negative
    double healthWidth = (health / maxHealth).clamp(0.0, 1.0) * size.width;

    // Draw background bar (black border)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(5),
      ),
      paintBackground,
    );

    // Draw shrinking health bar (red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, healthWidth, size.height),
        Radius.circular(5),
      ),
      paintHealth,
    );

    // Draw boss name dynamically
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.height * 0.7,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: bossName, // ✅ Uses dynamic boss name
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final textX = (size.width - textPainter.width) / 2;
    final textY = (size.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant BossHealthBarPainter oldDelegate) {
    return oldDelegate.health != health || oldDelegate.maxHealth != maxHealth;
  }
}

class RetryOverlay extends StatelessWidget {
  final RogueShooterGame game;

  const RetryOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Game Over",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await game.restartGame(context);
                  game.overlays.remove('retryOverlay');
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                  backgroundColor: const Color.fromARGB(255, 6, 6, 6),
                ),
                child: const Text("Retry"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => game.navigateToMainMenu(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                  backgroundColor: const Color.fromARGB(255, 6, 6, 6),
                ),
                child: const Text("Quit to Main Menu"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FadeTransitionOverlay extends StatefulWidget {
  final VoidCallback onFadeComplete;

  const FadeTransitionOverlay({Key? key, required this.onFadeComplete})
      : super(key: key);

  @override
  _FadeTransitionOverlayState createState() => _FadeTransitionOverlayState();
}

class _FadeTransitionOverlayState extends State<FadeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Adjust fade duration
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        widget.onFadeComplete(); // Call restart function after fade-in
        _controller.reverse(); // Fade back out
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class StaggerBarPainter extends CustomPainter {
  final double currentStagger;
  final double maxStagger;

  StaggerBarPainter(this.currentStagger, this.maxStagger);

  @override
  void paint(Canvas canvas, Size size) {
    // Background Bar with rounded edges
    Paint backgroundPaint = Paint()..color = const Color(0xFF444444);
    RRect backgroundRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, 0, size.width, size.height),
      Radius.circular(8), // Radius for rounded corners
    );
    canvas.drawRRect(backgroundRRect, backgroundPaint);

    // Fill Bar - Represents the current stagger value with rounded edges
    if (currentStagger > 0) {
      Paint fillPaint = Paint()..color = const Color(0xFFFFD700); // Gold color
      double barWidth = (currentStagger / maxStagger) * size.width;
      RRect fillRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(0, 0, barWidth, size.height),
        Radius.circular(8), // Radius for rounded corners
      );
      canvas.drawRRect(fillRRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever the stagger value changes
  }
}
