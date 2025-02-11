import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/effects/damagenumber.dart';
import 'package:whisper_warriors/game/main.dart'; // Adjust the path as necessary
// Import your RogueShooterGame

mixin Staggerable on PositionComponent, HasGameRef<RogueShooterGame> {
  double staggerProgress = 0.0;
  bool isStaggered = false;
  double staggerThreshold = 25000; // Stagger threshold for damage
  double staggerWindow = 3.0;
  double staggerDuration = 3.0;
  double staggerCooldown = 5.0;
  double staggerDamageMultiplier = 2.0;

  double _damageReceived = 0;
  double _staggerTimer = 0;
  double _staggerCooldownTimer = 0;
  final double _staggerFillRate = 0.0001;
  double _damageTickTime = 0.0;

  ValueNotifier<double> bossStaggerNotifier = ValueNotifier(0);

  // Abstract methods to be implemented by the class using the mixin
  void
      applyStaggerVisuals(); // Apply any stagger visual effects like color changes
  double get speed; // Accessor for speed (from the boss or entity)
  double
      get attackCooldown; // Accessor for attack cooldown (from the boss or entity)
  set speed(double newSpeed); // Setter for speed (to change it during stagger)
  set attackCooldown(double newAttackCooldown); // Setter for attack cooldown

  // Update stagger progress
  void updateStagger(double dt) {
    if (isStaggered) return; // Don't update while staggered

    if (_staggerTimer > 0) {
      _staggerTimer -= dt;
      if (_staggerTimer <= 0) {
        _damageReceived = 0;
      }
    }

    if (_staggerCooldownTimer > 0) {
      _staggerCooldownTimer -= dt;
    }

    // Damage applied at regular intervals
    _damageTickTime += dt;
    if (_damageTickTime >= 0.5) {
      _damageTickTime = 0.0; // Reset the timer
      _applyStaggerProgress();
    }
  }

  void _applyStaggerProgress() {
    if (_damageReceived > 0) {
      staggerProgress += (_damageReceived / staggerThreshold) *
          _staggerFillRate; // Gradual increase in stagger progress
      bossStaggerNotifier.value = staggerProgress;

      if (staggerProgress >= 1.0) {
        staggerProgress = 1.0;
        if (_staggerCooldownTimer <= 0) {
          triggerStagger();
        }
      }
    }
  }

  void applyStaggerDamage(int damage, {bool isCritical = false}) {
    if (isStaggered) return;

    _damageReceived += damage;
    _staggerTimer = staggerWindow;

    // Check if damage is enough to trigger stagger
    if (_damageReceived >= staggerThreshold && _staggerCooldownTimer <= 0) {
      triggerStagger();
    }

    // Create damage numbers when hitting the boss
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

    // Apply stagger visuals like color change and effects
    applyStaggerVisuals();

    // Reset stagger after the duration
    Future.delayed(Duration(seconds: staggerDuration.toInt()), () {
      isStaggered = false;
      speed /= 0.5; // Restore original speed
      attackCooldown /= 1.5; // Restore original attack cooldown
      staggerProgress = 0;
      bossStaggerNotifier.value = 0;
    });
  }

  double getStaggeredDamage(int baseDamage) {
    return (isStaggered ? baseDamage * staggerDamageMultiplier : baseDamage)
        .toDouble();
  }
}
