import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'package:whisper_warriors/game/main.dart';

class WhisperWarrior extends SpriteAnimationComponent
    with HasGameRef<RogueShooterGame>, CollisionCallbacks {
  late Map<String, SpriteAnimation> animations;
  bool isLoaded = false;
  String currentAnimation = 'idle';

  WhisperWarrior()
      : super(
          size: Vector2(128, 128),
          paint: Paint()
            ..imageFilter = ImageFilter.blur(sigmaX: 0, sigmaY: 0)
            ..colorFilter = ColorFilter.mode(
              Color.fromRGBO(70, 130, 180, 0.4), // Increased opacity to 0.4
              BlendMode.srcATop,
            ),
        );

  @override
  Future<void> onLoad() async {
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
        row: 0, stepTime: 0.1, from: 0, to: 10);

    // ✅ Load the hit animation from `whisper_warrior_hit.png`
    final hitSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('whisper_warrior_hit.png'),
      srcSize: Vector2(128, 128),
    );
    animations['hit'] =
        hitSpriteSheet.createAnimation(row: 0, stepTime: 0.125, from: 0, to: 5);

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
  }

  void playAnimation(String animationName) {
    if (!isLoaded) return;

    // Don't switch if we're already playing this animation (unless it's hit or death)
    if (currentAnimation == animationName &&
        animationName != 'hit' &&
        animationName != 'death') {
      return;
    }

    if (animations.containsKey(animationName)) {
      // Don't override death animation
      if (currentAnimation == 'death') {
        return;
      }

      // Don't override hit animation unless it's death
      if (currentAnimation == 'hit' && animationName != 'death') {
        return;
      }

      currentAnimation = animationName;

      if (animationName == 'hit') {
        animation = animations[animationName]!.clone();
        animation!.loop = false;
        print('👊 Playing hit animation');

        final double duration =
            animation!.frames.length * animation!.frames.first.stepTime;

        Future.delayed(Duration(milliseconds: (duration * 200).toInt()), () {
          if (currentAnimation == 'hit') {
            currentAnimation = 'idle';
            animation = animations['idle']!.clone();
          }
        });
      } else if (animationName == 'death') {
        animation = animations[animationName]!.clone();
        animation!.loop = false;

        final double duration =
            animation!.frames.length * animation!.frames.first.stepTime;

        Future.delayed(Duration(milliseconds: (duration * 100).toInt()), () {
          if (currentAnimation == 'death') {
            animation = SpriteAnimation.spriteList(
              [animation!.frames.last.sprite],
              stepTime: double.infinity,
            );
          }
        });
      } else {
        // For attack and idle animations
        animation =
            animations[animationName]!; // Don't clone regular animations
        animation!.loop = true;
      }
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

  @override
  void render(Canvas canvas) {
    // Render the shadow first
    canvas.save();
    canvas.translate(4, 4); // Increased offset from 2 to 4
    paint.imageFilter =
        ImageFilter.blur(sigmaX: 4, sigmaY: 4); // Increased blur spread
    super.render(canvas);
    canvas.restore();

    // Add a second shadow layer for more depth
    canvas.save();
    canvas.translate(2, 2);
    paint.imageFilter = ImageFilter.blur(sigmaX: 2, sigmaY: 2);
    super.render(canvas);
    canvas.restore();

    // Render the main sprite with increased contrast
    paint.imageFilter = null;
    paint.colorFilter = ColorFilter.matrix([
      1.2,
      0,
      0,
      0,
      0.1,
      0,
      1.2,
      0,
      0,
      0.1,
      0,
      0,
      1.2,
      0,
      0.1,
      0,
      0,
      0,
      1,
      0,
    ]);
    super.render(canvas);
  }
}
