import 'package:flutter/material.dart';

class GameTextStyles {
  static TextStyle gameTitle({
    Color color = Colors.white,
    double fontSize = 16,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'MyCustomFont',
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(2, 2),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.black,
          offset: Offset(-1, -1),
          blurRadius: 3,
        ),
      ],
    );
  }
}
