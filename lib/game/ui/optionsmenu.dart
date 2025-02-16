import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/ui/textstyles.dart';

class OptionsMenu extends StatelessWidget {
  final RogueShooterGame game;

  const OptionsMenu({Key? key, required this.game}) : super(key: key);

  Widget _buildButton(String text, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: GameTextStyles.gameTitle(fontSize: 20).copyWith(
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildButton(
              'Resume',
              () {
                game.resumeEngine();
                game.overlays.remove('optionsMenu');
              },
            ),
            const SizedBox(height: 10),
            _buildButton(
              'Damage Report',
              () {
                game.showDamageReport();
                game.overlays.remove('optionsMenu');
              },
            ),
            const SizedBox(height: 10),
            _buildButton(
              'Player Stats',
              () {
                game.showPlayerStats();
                game.overlays.remove('optionsMenu');
              },
            ),
            const SizedBox(height: 10),
            _buildButton(
              'Quit to Main Menu',
              () {
                game.overlays
                    .remove('optionsMenu'); // Remove options menu first
                game.quitToMainMenu(context); // Then quit to main menu
              },
            ),
          ],
        ),
      ),
    );
  }
}
