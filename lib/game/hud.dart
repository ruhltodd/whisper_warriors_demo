import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'experience.dart';
import 'main.dart';
import 'player.dart';
import 'abilitybar.dart';

class HUD extends StatelessWidget {
  final void Function(Vector2 delta) onJoystickMove;
  final SpiritBar experienceBar;
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
              painter: SpiritBarPainter(experienceBar),
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
        (spiritBar.spiritExp / spiritBar.spiritExpToNextLevel) * size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      progressPaint,
    );

    // Draw Spirit Level Text
    final textSpan = TextSpan(
      text: "Spirit Level ${spiritBar.spiritLevel}", // ✅ Updated variable
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
