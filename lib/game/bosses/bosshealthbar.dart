import 'package:flutter/material.dart';

class BossHealthBar extends StatelessWidget {
  final double bossHealth;
  final double maxBossHealth;

  const BossHealthBar({
    Key? key,
    required this.bossHealth,
    required this.maxBossHealth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double healthPercentage = (bossHealth / maxBossHealth).clamp(0.0, 1.0);

    return Container(
      width: 200,
      height: 15,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(5),
        color: Colors.black, // Background color
      ),
      child: Stack(
        children: [
          // 🔴 Health Bar (Red - Shrinks Dynamically)
          FractionallySizedBox(
            widthFactor: healthPercentage, // ✅ Correctly scales width
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // 🔢 Health Number (Always Centered)
          Center(
            child: Text(
              "${bossHealth.toInt()}", // ✅ Only show current health
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
