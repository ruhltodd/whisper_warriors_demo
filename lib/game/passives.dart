class PassiveEffect {
  final String name;
  final String description;
  final bool Function() condition; // ✅ When does this effect apply?
  final void Function() effect; // ✅ Effect to apply
  final void Function()?
      removeEffect; // ✅ Effect to remove when condition is false

  PassiveEffect({
    required this.name,
    required this.description,
    required this.condition,
    required this.effect,
    this.removeEffect,
  });
}
