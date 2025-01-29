import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'main.dart';

class WhisperWarrior extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Map<String, SpriteAnimation> animations;
  bool isLoaded = false;

  WhisperWarrior()
      : super(
          size: Vector2(64, 64),
          paint: Paint()..blendMode = BlendMode.srcOver,
        );

  @override
  Future<void> onLoad() async {
    print("Loading WhisperWarrior...");

    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_spritesheet.png'),
      srcSize: Vector2(64, 64),
    );

    // Load animations
    animations = {
      'idle': spriteSheet.createAnimation(row: 0, stepTime: 0.2),
      // 'walk': spriteSheet.createAnimation(row: 1, stepTime: 0.15),
      // 'attack': spriteSheet.createAnimation(row: 2, stepTime: 0.1),
      // 'hit': spriteSheet.createAnimation(row: 3, stepTime: 0.2),
//'death': spriteSheet.createAnimation(row: 4, stepTime: 0.25),
    };

    // Set initial animation
    animation = animations['idle'];
    isLoaded = true;

    print("WhisperWarrior loaded successfully!");
  }

  void playAnimation(String animationName) {
    if (!isLoaded) {
      print("Warning: Attempted to play animation before loading completed.");
      return;
    }

    if (animations.containsKey(animationName)) {
      animation = animations[animationName];
    } else {
      print('Animation "$animationName" not found.');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Ensure animations stay in sync with position and joystick input
    if (parent is PositionComponent) {
      position = (parent as PositionComponent).position;
    }
  }
}
