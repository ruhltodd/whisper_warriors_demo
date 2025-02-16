import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';

class XPBar extends StatelessWidget {
  final bool smallSize; // ✅ HUD version should be minimal

  const XPBar({this.smallSize = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: PlayerProgressManager.xpNotifier,
      builder: (context, xpValue, child) {
        int currentXp = PlayerProgressManager.getXp();
        int currentLevel = PlayerProgressManager.getLevel();
        int requiredXp = PlayerProgressManager.xpForNextLevel(currentLevel);
        double progress = currentXp / requiredXp;

        return Stack(
          alignment: Alignment.center, // ✅ Keeps everything centered
          children: [
            if (!smallSize) // ✅ Only show in Ability Selection Screen
              Container(
                width: 320,
                height: 70, // ⬆️ **Increased height to fully cover text**
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.6), // ✅ Dark overlay for readability
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!smallSize) // ✅ Hide level text in HUD
                  Text(
                    "Level $currentLevel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: smallSize ? 12 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: smallSize ? 1 : 5), // ⬆️ Small spacing fix

                // **XP Progress Bar**
                Container(
                  width: smallSize ? 150 : 300, // ✅ Smaller in HUD
                  height: smallSize ? 6 : 10,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white, width: smallSize ? 0.5 : 1),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!smallSize) SizedBox(height: 5), // ⬆️ Adjusted spacing
                if (!smallSize)
                  Text(
                    "$currentXp / $requiredXp XP",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
