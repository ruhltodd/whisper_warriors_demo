import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'abilities.dart';

class AbilityBar extends StatelessWidget {
  final Player player;

  AbilityBar({required this.player});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Ability>>(
      valueListenable: player.abilityNotifier, // ✅ Live updating abilities
      builder: (context, abilities, _) {
        return Row(
          children: abilities.map((ability) {
            return _buildAbilityIcon(ability);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAbilityIcon(Ability ability) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Image.asset(
            'assets/images/${ability.name.toLowerCase().replaceAll(" ", "_")}.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.flash_on, size: 32, color: Colors.white);
            },
          ),
        ],
      ),
    );
  }
}
