import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';
import 'package:whisper_warriors/game/ui/optionscreen.dart';

class MainMenu extends StatefulWidget {
  final Function startGame;
  final Function openOptions;

  MainMenu({required this.startGame, required this.openOptions, Key? key})
      : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  double startButtonOpacity = 1.0;
  double optionsButtonOpacity = 1.0;
  late final AudioManager _audioManager;

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

  void _openOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionsScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Fullscreen Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_background.png',
              fit: BoxFit.cover, // ✅ Ensures the image fills the screen
            ),
          ),

          // ✅ Centered UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ Centers buttons properly
              children: [
                // Title
                Padding(
                  padding:
                      EdgeInsets.only(top: 80), // ✅ Adjusted for better spacing
                ),

                SizedBox(height: 200),

                // ✅ Animated Start Button
                MouseRegion(
                  onEnter: (_) => setState(() => startButtonOpacity = 0.8),
                  onExit: (_) => setState(() => startButtonOpacity = 1.0),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => startButtonOpacity = 0.6),
                    onTapUp: (_) {
                      setState(() => startButtonOpacity = 1.0);
                      _stopMusic(); // ✅ Stop menu music
                      widget.startGame(); // ✅ Move to Ability Selection
                    },
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 150),
                      opacity: startButtonOpacity,
                      child: Image.asset(
                        'assets/images/start_button.png',
                        width: 250,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // ✅ Animated Options Button
                MouseRegion(
                  onEnter: (_) => setState(() => optionsButtonOpacity = 0.8),
                  onExit: (_) => setState(() => optionsButtonOpacity = 1.0),
                  child: GestureDetector(
                    onTapDown: (_) =>
                        setState(() => optionsButtonOpacity = 0.6),
                    onTapUp: (_) {
                      setState(() => optionsButtonOpacity = 1.0);
                      _openOptions(); // Use our new method instead of widget.openOptions()
                    },
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 150),
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
        ],
      ),
    );
  }
}
