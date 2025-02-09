import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';

mixin Staggerable on PositionComponent {
  double staggerProgress = 0.0;
  bool isStaggered = false;
  double staggerThreshold = 500;
  double staggerWindow = 3.0;
  double staggerDuration = 2.0;
  double staggerCooldown = 5.0;
  double staggerDamageMultiplier = 1.2;

  double _damageReceived = 0;
  double _staggerTimer = 0;
  double _staggerCooldownTimer = 0;

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
  }

  void applyStaggerDamage(int damage) {
    if (isStaggered) return;

    _damageReceived += damage;
    _staggerTimer = staggerWindow;

    if (_damageReceived >= staggerThreshold && _staggerCooldownTimer <= 0) {
      triggerStagger();
    }
  }

  void triggerStagger() {
    isStaggered = true;
    staggerProgress = 0.0; // ✅ Reset stagger meter
    _staggerCooldownTimer = staggerCooldown;
    _damageReceived = 0;

    add(ColorEffect(
      const Color(0x77FF0000),
      EffectController(duration: 0.3, alternate: true, repeatCount: 3),
    ));

    add(MoveEffect.by(
      Vector2(5, -5),
      EffectController(duration: 0.05, alternate: true, repeatCount: 5),
    ));

    add(ScaleEffect.to(
      Vector2.all(0.9),
      EffectController(duration: 0.2, alternate: true, repeatCount: 2),
    ));

    add(OpacityEffect.to(
      0.5,
      EffectController(duration: 0.2, alternate: true, repeatCount: 4),
    ));

    Future.delayed(Duration(seconds: staggerDuration.toInt()), () {
      isStaggered = false;
    });
  }

  double getStaggeredDamage(int baseDamage) {
    return (isStaggered ? baseDamage * staggerDamageMultiplier : baseDamage)
        .toDouble();
  }
}
