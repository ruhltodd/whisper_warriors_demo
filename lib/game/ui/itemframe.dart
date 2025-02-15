import 'package:flutter/material.dart';

class AnimatedItemFrame extends StatefulWidget {
  final Color rarityColor;
  final Widget child;

  const AnimatedItemFrame({
    required this.rarityColor,
    required this.child,
    super.key,
  });

  @override
  State<AnimatedItemFrame> createState() => _AnimatedItemFrameState();
}

class _AnimatedItemFrameState extends State<AnimatedItemFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 3.14 * 2,
              transform: GradientRotation(_controller.value * 2 * 3.14),
              colors: [
                widget.rarityColor.withOpacity(0.2),
                widget.rarityColor.withOpacity(0.6),
                widget.rarityColor.withOpacity(0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.rarityColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
