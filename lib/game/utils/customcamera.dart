import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CustomCamera {
  // Force fixed game size
  final Vector2 gameSize = Vector2(820, 820);
  final Vector2 worldSize;
  Vector2 position = Vector2.zero();
  double followSpeed = 5.0;

  CustomCamera({
    required Vector2 rawScreenSize, // Keep parameter but ignore it
    required this.worldSize,
  });

  void follow(Vector2 playerPosition, double dt) {
    // Center the camera by offsetting from the player position
    Vector2 centerOffset = gameSize / 2;
    Vector2 targetPosition = playerPosition - centerOffset;

    // Add a horizontal offset to center the character (adjust 100 as needed)
    targetPosition.x += 100; // Adjust this value to shift camera right/left

    // Smooth follow
    position.x += (targetPosition.x - position.x) * followSpeed * dt;
    position.y += (targetPosition.y - position.y) * followSpeed * dt;

    // Clamp to world bounds
    position.x = position.x.clamp(0, worldSize.x - gameSize.x);
    position.y = position.y.clamp(0, worldSize.y - gameSize.y);

    // Debug print
    print(
      '📸 Camera Target: $targetPosition, Current: $position, Player: $playerPosition',
    );
  }

  void applyTransform(Canvas canvas) {
    // Center the game view
    final scale = gameSize.x / 820; // Calculate scale factor if needed
    canvas.scale(scale);
    canvas.translate(-position.x, -position.y);
  }
}

/*class CustomCamera {
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
