import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';
import 'package:whisper_warriors/game/ui/optionscreen.dart';
import 'package:whisper_warriors/game/ui/screentransition.dart';
import 'package:whisper_warriors/game/ui/game_viewport.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameViewport(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: AssetImage('assets/images/main_menu_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 200),

              // 🎮 Start Button
              _buildAnimatedButton(
                image: 'assets/images/start_button.png',
                onTap: () {
                  _stopMusic();
                  widget.startGame();
                },
              ),

              const SizedBox(height: 30),

              // ⚙️ Options Button
              _buildAnimatedButton(
                image: 'assets/images/options_button.png',
                onTap: () {
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔄 Helper function for buttons
  Widget _buildAnimatedButton(
      {required String image, required VoidCallback onTap}) {
    return MouseRegion(
      onEnter: (_) => setState(() => startButtonOpacity = 0.8),
      onExit: (_) => setState(() => startButtonOpacity = 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => startButtonOpacity = 0.6),
        onTapUp: (_) {
          setState(() => startButtonOpacity = 1.0);
          onTap();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: startButtonOpacity,
          child: Image.asset(image, width: 250),
        ),
      ),
    );
  }
}
