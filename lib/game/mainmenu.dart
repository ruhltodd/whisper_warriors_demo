import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  final Function startGame;
  final Function openOptions;

  MainMenu({required this.startGame, required this.openOptions, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Fullscreen Background
        Positioned.fill(
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/main_menu_background.png', // Ensure path is correct
              fit: BoxFit.cover, // ✅ Makes sure it covers entire screen
            ),
          ),
        ),

        // ✅ UI Elements (Title + Buttons)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 200),

              // ✅ Start Button
              GestureDetector(
                onTap: () => startGame(),
                child: Image.asset(
                  'assets/images/start_button.png', // Ensure path is correct
                  width: 250,
                ),
              ),

              SizedBox(height: 20),

              // ✅ Options Button
              GestureDetector(
                onTap: () => openOptions(),
                child: Image.asset(
                  'assets/images/options_button.png', // Ensure path is correct
                  width: 250,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
