import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';
import 'package:whisper_warriors/game/ui/optionscreen.dart';
import 'package:whisper_warriors/game/ui/screentransition.dart';

class MainMenu extends StatefulWidget {
  final VoidCallback startGame;

  const MainMenu({
    required this.startGame,
    super.key,
  });

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late AudioManager _audioManager;
  double startButtonOpacity = 1.0;
  double optionsButtonOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    _playBackgroundMusic();
  }

  void _playBackgroundMusic() async {
    await _audioManager.playBackgroundMusic('audio/mystical-winds.mp3');
  }

  void _stopMusic() async {
    await _audioManager.stopBackgroundMusic();
  }

  @override
  void dispose() {
    _stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/main_menu_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 200),

            // Animated Start Button
            MouseRegion(
              onEnter: (_) => setState(() => startButtonOpacity = 0.8),
              onExit: (_) => setState(() => startButtonOpacity = 1.0),
              child: GestureDetector(
                onTapDown: (_) => setState(() => startButtonOpacity = 0.6),
                onTapUp: (_) {
                  setState(() => startButtonOpacity = 1.0);
                  _stopMusic();
                  widget.startGame();
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: startButtonOpacity,
                  child: Image.asset(
                    'assets/images/start_button.png',
                    width: 250,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Animated Options Button
            MouseRegion(
              onEnter: (_) => setState(() => optionsButtonOpacity = 0.8),
              onExit: (_) => setState(() => optionsButtonOpacity = 1.0),
              child: GestureDetector(
                onTapDown: (_) => setState(() => optionsButtonOpacity = 0.6),
                onTapUp: (_) {
                  setState(() => optionsButtonOpacity = 1.0);
                  Navigator.push(
                    context,
                    GamePageTransition(
                      builder: (context) => OptionsScreen(
                        onBack: () => Navigator.pop(context),
                      ),
                      transitionType: TransitionType.fade,
                      duration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: optionsButtonOpacity,
                  child: Image.asset(
                    'assets/images/options_button.png',
                    width: 250,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
