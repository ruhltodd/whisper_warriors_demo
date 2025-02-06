import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:whisper_warriors/game/inventorybar.dart';
import 'experience.dart';
import 'main.dart';
import 'abilitybar.dart';
import 'bosshealthbar.dart';
import 'staggerbar.dart';
import 'dart:ui' as ui;

class HUD extends StatelessWidget {
  final void Function(Vector2 delta) onJoystickMove;
  final SpiritBar experienceBar;
  final RogueShooterGame game;
  final ValueNotifier<double?> bossHealthNotifier;
  final ValueNotifier<double?> bossStaggerNotifier; // ✅ Track stagger progress

  HUD({
    required this.onJoystickMove,
    required this.experienceBar,
    required this.game,
    required this.bossHealthNotifier,
    required this.bossStaggerNotifier, // ✅ Track stagger bar
  });

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top;
    print(
        "👜 Current Inventory: ${game.player.inventory.map((item) => item.name).toList()}");
    return Stack(
      children: [
        // ⏳ Game Timer (Top Right)
        Positioned(
          top: safeTop + 10,
          right: 20,
          child: ValueListenableBuilder<int>(
            valueListenable: game.gameHudNotifier,
            builder: (context, time, _) {
              return Text(
                game.formatTime(time),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MyCustomFont',
                ),
              );
            },
          ),
        ),

        // ⚡ Spirit Bar (Top Center)
        Positioned(
          top: safeTop + 10,
          left: MediaQuery.of(context).size.width / 2 - 100, // ✅ Centered
          child: SizedBox(
            width: 200,
            height: 20,
            child: CustomPaint(
              painter: SpiritBarPainter(experienceBar),
            ),
          ),
        ),

        // 👑 Boss UI (Health Bar + Stagger Bar)
        Positioned(
          top: safeTop + 40,
          left: MediaQuery.of(context).size.width / 2 - 100, // ✅ Centered UI
          child: ValueListenableBuilder<double?>(
            valueListenable: bossHealthNotifier,
            builder: (context, bossHealth, _) {
              if (bossHealth == null) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 👑 Boss Name
                  Text(
                    'Umbrathos, The Fading King',
                    textAlign: TextAlign.center, // ✅ Centered text
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MyCustomFont',
                    ),
                  ),
                  const SizedBox(height: 5),

                  // 🔴 **Boss Health Bar (Now Centered)**
                  SizedBox(
                    width: 200, // ✅ Fixed width for proper centering
                    child: BossHealthBar(
                      bossHealth: bossHealth,
                      maxBossHealth: 50000,
                    ),
                  ),

                  const SizedBox(height: 5), // ✅ Small spacing between bars

                  // ⚡ **Stagger Bar (Perfectly Aligned Below Health Bar)**
                  ValueListenableBuilder<double?>(
                    valueListenable: bossStaggerNotifier,
                    builder: (context, stagger, child) {
                      if (stagger == null) return SizedBox.shrink();
                      return SizedBox(
                        width: 200, // ✅ Matches health bar width
                        height: 8, // ✅ Slightly smaller than health bar
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(5), // ✅ Rounded Corners
                          child: Stack(
                            children: [
                              // Background (Black Border)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),

                              // **Fill Bar** (Stagger Progress)
                              FractionallySizedBox(
                                widthFactor: stagger / 100, // ✅ Adjust per boss
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors
                                        .amber, // ✅ Gold Color for Stagger
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // 🔥 Ability Bar (Top Left)
        Positioned(
          top: safeTop + 10,
          left: 10,
          child: AbilityBar(player: game.player),
        ),

        // 🛡 Inventory Bar (Below the Ability Bar)
        Positioned(
          top: safeTop +
              70, // Adjust this value if needed based on your AbilityBar's height
          left: 10,
          child: InventoryBar(player: game.player),
        ),
        // 🎮 Joystick (Bottom Left)
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

    // ✅ Draw Spirit Level Text
    final TextSpan textSpan = TextSpan(
      text: "Spirit Level ${spiritBar.spiritLevel}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: 'MyCustomFont',
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

  BossHealthBarPainter(this.health);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final paintHealth = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw background bar
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), paintBackground);

    // Draw health bar
    double healthWidth = (health / 5000) * size.width; // ✅ Scale health bar
    canvas.drawRect(Rect.fromLTWH(0, 0, healthWidth, size.height), paintHealth);

    // Draw boss name "Umbrathos, The Fading King"
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.height * 0.7, // Scale text size to fit
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: "Umbrathos, The Fading King",
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
          Text(
            "Game Over",
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              game.restartGame(context); // ✅ Pass `context` argument
              game.overlays.remove('retryOverlay'); // ✅ Hide overlay
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: TextStyle(fontSize: 20),
              backgroundColor: const Color.fromARGB(255, 6, 6, 6),
            ),
            child: Text("Retry"),
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
