import 'package:flutter/material.dart';

class BossHealthBar extends StatelessWidget {
  final double bossHealth;
  final double maxBossHealth;
  final double segmentSize;

  const BossHealthBar({
    Key? key,
    required this.bossHealth,
    required this.maxBossHealth,
    this.segmentSize = 1000,
  }) : super(key: key);

  Color _getSegmentColor(int segmentNumber) {
    final colors = [
      Colors.purple.withOpacity(0.85),
      Colors.blue.withOpacity(0.85),
      Colors.green.withOpacity(0.85),
      Colors.yellow.withOpacity(0.85),
      Colors.orange.withOpacity(0.85),
      Colors.red.withOpacity(0.85),
      Colors.pink.withOpacity(0.85),
      Colors.teal.withOpacity(0.85),
      Colors.lime.withOpacity(0.85),
      Colors.indigo.withOpacity(0.85),
      Colors.cyan.withOpacity(0.85),
      Colors.amber.withOpacity(0.85),
    ];
    return colors[segmentNumber % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    int currentSegment = (bossHealth / segmentSize).ceil();
    int totalSegments = (maxBossHealth / segmentSize).ceil();
    double remainingInSegment = bossHealth % segmentSize;
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
          // Next segment color (background)
          if (currentSegment > 0)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getSegmentColor(currentSegment - 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

          // Current segment color (depleting)
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

          // Segment label on the right
          Positioned(
            right: 5,
            child: Center(
              child: Text(
                'X$currentSegment',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.8),
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
  }
}
