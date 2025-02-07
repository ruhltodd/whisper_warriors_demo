import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'abilities.dart';

class AbilityBar extends StatelessWidget {
  final Player player;

  AbilityBar({required this.player});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Ability>>(
      valueListenable: player.abilityNotifier, // ✅ Live updating abilities
      builder: (context, abilities, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                Colors.black.withOpacity(0.6), // ✅ Semi-transparent background
            borderRadius: BorderRadius.circular(15), // ✅ Rounded edges
            border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1), // ✅ Optional border
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: abilities.map((ability) {
              return _buildAbilityIcon(ability);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAbilityIcon(Ability ability) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8), // ✅ Makes the icon rounded
        child: Image.asset(
          'assets/images/${ability.name.toLowerCase().replaceAll(" ", "_")}.png',
          width: 32,
          height: 32,
          fit:
              BoxFit.cover, // ✅ Ensures the image fits within the rounded frame
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              backgroundColor:
                  Colors.white.withOpacity(0.2), // ✅ Placeholder background
              radius: 16,
              child: Icon(Icons.flash_on, size: 20, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
