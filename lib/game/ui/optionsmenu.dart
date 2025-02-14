import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';

class OptionsMenu extends StatelessWidget {
  final RogueShooterGame game;

  const OptionsMenu({Key? key, required this.game}) : super(key: key);

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5), // Material Blue 600
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
          foregroundColor: Colors.black, // Set default text color to black
        ),
        child: Text(text),
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
          color: const Color(0xFF2196F3).withOpacity(0.9), // Material Blue 500
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF64B5F6), // Material Blue 300
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
