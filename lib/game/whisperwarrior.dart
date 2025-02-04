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
          size: Vector2(128, 128),
          paint: Paint()..blendMode = BlendMode.srcOver,
        );

  @override
  Future<void> onLoad() async {
    print("Loading WhisperWarrior...");

    animations = {};

    // ✅ Load the idle animation from `whisper_warrior_idle.png`
    final idleSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_idle.png'),
      srcSize: Vector2(128, 128),
    );
    animations['idle'] =
        idleSpriteSheet.createAnimation(row: 0, stepTime: 0.4, from: 0, to: 5);

    /* // ✅ Load the walk animation from `whisper_warrior_walk.png`
    final walkSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_idle.png'),
      srcSize: Vector2(128, 128),
    );
    animations['walk'] =
        walkSpriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 0, to: 5); */

    // ✅ Load the attack animation from `whisper_warrior_attack.png`
    final attackSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_attack.png'),
      srcSize: Vector2(128, 128),
    );
    animations['attack'] = attackSpriteSheet.createAnimation(
        row: 0, stepTime: 0.15, from: 0, to: 10);

    // ✅ Load the hit animation from `whisper_warrior_hit.png`
    final hitSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_hit.png'),
      srcSize: Vector2(128, 128),
    );
    animations['hit'] =
        hitSpriteSheet.createAnimation(row: 0, stepTime: 0.15, from: 0, to: 5);

    // ✅ Load the death animation from `whisper_warrior_death.png`
    final deathSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_death.png'),
      srcSize: Vector2(128, 128),
    );
    animations['death'] = deathSpriteSheet.createAnimation(
        row: 0, stepTime: 0.25, from: 0, to: 5);

    // Set the default animation
    animation = animations['idle'];
    isLoaded = true;

    print("WhisperWarrior loaded successfully with multiple animations!");
  }

  void playAnimation(String animationName) {
    if (!isLoaded) {
      print("Warning: Attempted to play animation before loading completed.");
      return;
    }

    if (animations.containsKey(animationName)) {
      animation = animations[animationName];

      if (animationName == 'death') {
        print("☠️ Playing death animation...");

        // ✅ Prevent looping by setting `loop` to false
        animation!.loop = false;

        // ✅ Get animation duration correctly
        final double duration =
            animation!.frames.length * animation!.frames.first.stepTime;

        Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
          print("☠️ Death animation finished, freezing on last frame.");
          animation = SpriteAnimation.spriteList(
            [animation!.frames.last.sprite], // ✅ Freeze on last frame
            stepTime: double.infinity,
          );
        });
      }
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
