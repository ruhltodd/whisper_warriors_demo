import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/main.dart'; // Adjust the path as necessary

mixin Staggerable on PositionComponent, HasGameRef<RogueShooterGame> {
  double staggerProgress = 0.0;
  bool isStaggered = false;
  double staggerWindow = 3.0;
  double staggerDuration = 3.0;
  double staggerCooldown = 5.0;
  double staggerDamageMultiplier = 1.0;

  double _damageReceived = 0;
  double _staggerTimer = 0;
  double _staggerCooldownTimer = 0;
  static const double _staggerFillRate = 0.5 / 20000;
  double _damageTickTime = 0.0;

  ValueNotifier<double> bossStaggerNotifier = ValueNotifier(0);

  void
      applyStaggerVisuals(); // Apply any stagger visual effects like color changes

  double get speed; // Accessor for speed
  double get attackCooldown; // Accessor for attack cooldown
  set speed(double newSpeed); // Setter for speed
  set attackCooldown(double newAttackCooldown); // Setter for attack cooldown

  void updateStagger(double dt) {
    if (isStaggered) return;

    if (_staggerTimer > 0) {
      _staggerTimer -= dt;
      if (_staggerTimer <= 0) {
        _damageReceived = 0;
      }
    }

    if (_staggerCooldownTimer > 0) {
      _staggerCooldownTimer -= dt;
    }

    _damageTickTime += dt;
    if (_damageTickTime >= 0.5) {
      _damageTickTime = 0.0;
      _applyStaggerProgress();
    }
  }

  void _applyStaggerProgress() {
    if (_damageReceived > 0) {
      staggerProgress += (_damageReceived * _staggerFillRate);
      staggerProgress = staggerProgress.clamp(0.0, 100.0);
      bossStaggerNotifier.value = staggerProgress;
    }
  }

  void applyStaggerDamage(int damage, {bool isCritical = false}) {
    // Do not skip the damage application when staggered
    _damageReceived += damage;
    _staggerTimer = staggerWindow;
    _applyStaggerProgress();

    // Trigger stagger when progress reaches 100%
    if (staggerProgress >= 100.0 && _staggerCooldownTimer <= 0) {
      triggerStagger();
    }

    // Create and display damage number regardless of stagger state
    final damageNumber = DamageNumber(
      damage,
      position.clone() + Vector2(0, -20),
      isCritical: isCritical,
    );
    gameRef.add(damageNumber);
  }

  void triggerStagger() {
    isStaggered = true;
    staggerProgress = 0.0;
    _staggerCooldownTimer = staggerCooldown;
    _damageReceived = 0;

    applyStaggerVisuals();

    Future.delayed(Duration(seconds: staggerDuration.toInt()), () {
      isStaggered = false;
      speed /= 0.5;
      attackCooldown /= 1.5;
      staggerProgress = 0;
      bossStaggerNotifier.value = 0;
    });
  }

  double getStaggeredDamage(int baseDamage) {
    return (isStaggered ? baseDamage * staggerDamageMultiplier : baseDamage)
        .toDouble();
  }
}
