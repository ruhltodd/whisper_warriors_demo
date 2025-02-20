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
            opacity: startButtonOpacity,
            onHover: (value) =>
                setState(() => startButtonOpacity = value ? 0.8 : 1.0),
            onTapDown: () => setState(() => startButtonOpacity = 0.6),
            onTapUp: () => setState(() => startButtonOpacity = 1.0),
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
            opacity: optionsButtonOpacity,
            onHover: (value) =>
                setState(() => optionsButtonOpacity = value ? 0.8 : 1.0),
            onTapDown: () => setState(() => optionsButtonOpacity = 0.6),
            onTapUp: () => setState(() => optionsButtonOpacity = 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String image,
    required VoidCallback onTap,
    required double opacity,
    required Function(bool) onHover,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapUp,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: Image.asset(image, width: 250),
        ),
      ),
    );
  }
}
