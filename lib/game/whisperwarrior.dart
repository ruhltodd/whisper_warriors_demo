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
  JoystickComponent? joystick; // Joystick reference for movement

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

    animations = {
      'idle': spriteSheet.createAnimation(row: 0, stepTime: 0.2),
      //  'walk': spriteSheet.createAnimation(row: 1, stepTime: 0.15),
      //  'attack': spriteSheet.createAnimation(row: 2, stepTime: 0.1),
      //  'hit': spriteSheet.createAnimation(row: 3, stepTime: 0.2),
      //  'death': spriteSheet.createAnimation(row: 4, stepTime: 0.25),
    };

    animation = animations['idle'];
    isLoaded = true;

    print("WhisperWarrior loaded successfully!");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle joystick movement
    if (joystick != null && joystick!.delta.length > 0) {
      // Move the WhisperWarrior based on joystick input
      position +=
          joystick!.delta.normalized() * 200 * dt; // Adjust speed as needed

      // Play walk animation when moving
      if (animation != animations['walk']) {
        animation = animations['walk'];
      }
    } else {
      // Play idle animation when not moving
      if (animation != animations['idle']) {
        animation = animations['idle'];
      }
    }
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
}
