import 'package:flutter/material.dart';

class AbilitySelectionScreen extends StatefulWidget {
  @override
  _AbilitySelectionScreenState createState() => _AbilitySelectionScreenState();
}

class _AbilitySelectionScreenState extends State<AbilitySelectionScreen> {
  final int maxAbilities = 10;
  final Map<String, String> abilityDescriptions = {
    'offensive': 'Increases attack power and damage output.',
    'defensive': 'Boosts defense and reduces incoming damage.',
    'utility': 'Provides special effects like speed boosts or healing.',
  };

  final List<String> selectedAbilities = [];
  String selectedDescription = "Select an ability to see its description.";

  void toggleAbility(String ability) {
    setState(() {
      if (selectedAbilities.contains(ability)) {
        selectedAbilities.remove(ability);
      } else if (selectedAbilities.length < maxAbilities) {
        selectedAbilities.add(ability);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Select 10 Abilities",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAbilityColumn(
                  "Offensive", 'assets/images/offensive_icon.png', 'offensive'),
              _buildAbilityColumn(
                  "Defensive", 'assets/images/defensive_icon.png', 'defensive'),
              _buildAbilityColumn(
                  "Utility", 'assets/images/utility_icon.png', 'utility'),
            ],
          ),
          SizedBox(height: 30),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(selectedDescription,
                style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectedAbilities.length == maxAbilities
                ? () => print("Confirmed!")
                : null,
            child: Text("Confirm Selection"),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityColumn(
      String title, String iconPath, String abilityType) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              toggleAbility(abilityType);
              setState(() {
                selectedDescription =
                    abilityDescriptions[abilityType] ?? "Unknown ability.";
              });
            },
            child: Image.asset(iconPath, width: 80, height: 80),
          ),
        ],
      ),
    );
  }
}
