import 'package:flutter/material.dart';

class GameViewport extends StatelessWidget {
  final Widget child;

  const GameViewport({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SizedBox(
          width: 820,
          height: 820,
          child: child,
        ),
      ),
    );
  }
}
