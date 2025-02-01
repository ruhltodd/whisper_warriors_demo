import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late final AudioPlayer _bgmPlayer;

  @override
  void initState() {
    super.initState();
    _bgmPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  void _playBackgroundMusic() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // ✅ Loop the music
    await _bgmPlayer.play(AssetSource('music/mystical-winds.mp3'));
  }

  void _stopMusic() async {
    await _bgmPlayer.stop(); // ✅ Stop music when leaving menu
  }

  @override
  void dispose() {
    _stopMusic();
    _bgmPlayer.dispose();
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
                      widget.openOptions(); // ✅ Open Options
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
