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
    return Container(
      width: 200,
      height: 15,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(5),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: bossHealth / maxBossHealth, // ✅ Dynamic width
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Center(
            child: Text(
              "${bossHealth.toInt()} / ${maxBossHealth.toInt()}",
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
