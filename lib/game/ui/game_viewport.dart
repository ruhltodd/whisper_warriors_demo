import 'package:flutter/material.dart';

class GameViewport extends StatelessWidget {
  final Widget child;

  const GameViewport({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            width: 820,
            height: 820,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
