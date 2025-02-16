import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BossHealthBar extends StatelessWidget {
  final double maxBossHealth;
  final double segmentSize;
  final int alpha;
  final ValueListenable<double> bossHealth; // <--- ValueListenable

  BossHealthBar({
    Key? key,
    required this.bossHealth,
    required this.maxBossHealth,
    this.segmentSize = 1000,
    this.alpha = 128,
  }) : super(key: key);

  int get currentSegment => (bossHealth.value / segmentSize).ceil();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      // <--- Use ValueListenableBuilder
      valueListenable: bossHealth,
      builder: (context, healthValue, child) {
        int totalSegments = (maxBossHealth / segmentSize).ceil();
        double remainingInSegment = healthValue % segmentSize;
        double segmentPercentage = remainingInSegment / segmentSize;

        return Container(
          width: 300,
          height: 25,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.85)),
            borderRadius: BorderRadius.circular(5),
            color: Colors.black38,
          ),
          child: Stack(
            children: [
              if (currentSegment > 0)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getSegmentColor(currentSegment - 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              if (currentSegment > 0)
                FractionallySizedBox(
                  widthFactor: segmentPercentage,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSegmentColor(currentSegment - 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              Positioned(
                right: 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    'X$currentSegment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSegmentColor(int segmentNumber) {
    final colors = [
      Colors.purple.withAlpha(alpha),
      Colors.blue.withAlpha(alpha),
      Colors.green.withAlpha(alpha),
      Colors.yellow.withAlpha(alpha),
      Colors.orange.withAlpha(alpha),
      Colors.red.withAlpha(alpha),
      Colors.pink.withAlpha(alpha),
      Colors.teal.withAlpha(alpha),
      Colors.lime.withAlpha(alpha),
      Colors.indigo.withAlpha(alpha),
      Colors.cyan.withAlpha(alpha),
      Colors.amber.withAlpha(alpha),
    ];
    return colors[segmentNumber % colors.length];
  }
}
