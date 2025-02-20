import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CustomCamera {
  // Force fixed game size
  final Vector2 gameSize = Vector2(820, 820);
  final Vector2 worldSize;
  Vector2 position = Vector2.zero();
  double followSpeed = 5.0;

  // Calculate the world center offset
  late final Vector2 worldCenter;

  CustomCamera({
    required Vector2 rawScreenSize, // Keep parameter but ignore it
    required this.worldSize,
  }) {
    // Calculate the center point of the world
    worldCenter = worldSize / 2;
    // Initialize camera position to center
    position = Vector2(
        worldCenter.x - (gameSize.x / 2), worldCenter.y - (gameSize.y / 2));
  }

  void follow(Vector2 playerPosition, double dt) {
    // Calculate target position relative to world center
    Vector2 targetPosition = Vector2(playerPosition.x - (gameSize.x / 2),
        playerPosition.y - (gameSize.y / 2));

    // Smooth follow
    position.x += (targetPosition.x - position.x) * followSpeed * dt;
    position.y += (targetPosition.y - position.y) * followSpeed * dt;

    // Clamp to world bounds
    position.x = position.x.clamp(0, worldSize.x - gameSize.x);
    position.y = position.y.clamp(0, worldSize.y - gameSize.y);

    // Debug print
    print(
        '📸 Target: $targetPosition, Camera: $position, Player: $playerPosition, World Center: $worldCenter');
  }

  void applyTransform(Canvas canvas) {
    canvas.translate(-position.x, -position.y);
  }
}

/*
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
}*/
