import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/main.dart';
import 'package:whisper_warriors/game/ui/textstyles.dart';

class OptionsMenu extends StatelessWidget {
  final RogueShooterGame? game;

  const OptionsMenu({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (game == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options',
              style: GameTextStyles.gameTitle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game!.resumeGame();
                game!.overlays.remove('optionsMenu');
              },
              child: const Text('Resume'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => game!.showDamageReport(),
              child: const Text('Damage Report'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => game!.showPlayerStats(),
              child: const Text('Player Stats'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => game!.quitToMainMenu(context),
              child: const Text('Quit to Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
