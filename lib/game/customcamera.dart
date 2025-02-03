import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CustomCamera {
  final Vector2 screenSize;
  final Vector2 worldSize;
  Vector2 position = Vector2.zero();
  double followSpeed = 5.0;

  CustomCamera({
    required this.screenSize,
    required this.worldSize,
  });

  void follow(Vector2 playerPosition, double dt) {
    final desiredPosition = playerPosition - screenSize / 2;
    position.x += (desiredPosition.x - position.x) * followSpeed * dt;
    position.y += (desiredPosition.y - position.y) * followSpeed * dt;

    position.x = position.x.clamp(0, worldSize.x - screenSize.x);
    position.y = position.y.clamp(0, worldSize.y - screenSize.y);
  }

  void applyTransform(Canvas canvas) {
    canvas.translate(-position.x, -position.y);
  }
}
