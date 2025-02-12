import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/ui/globalexperiencelevelbar.dart'; // ✅ Added for ability unlocks

class AbilitySelectionScreen extends StatefulWidget {
  final Function(List<String>) onAbilitiesSelected;

  AbilitySelectionScreen({required this.onAbilitiesSelected, Key? key})
      : super(key: key);

  @override
  _AbilitySelectionScreenState createState() => _AbilitySelectionScreenState();
}

class _AbilitySelectionScreenState extends State<AbilitySelectionScreen> {
  List<String> selectedAbilities = [];
  final int maxAbilities = 4;
  late AudioPlayer _audioPlayer;
  late List<String> unlockedAbilities; // ✅ Store unlocked abilities

  final Map<String, String> abilities = {
    'Whispering Flames':
        'Whispering Flames: A fire aura that burns enemies near you.',
    'Soul Fracture':
        'Soul Fracture: Enemies explode into ghostly shrapnel on death.',
    'Shadow Blades':
        'Shadow Blades: Throws shadow blades that pierce through enemies.',
    'Cursed Echo':
        'Cursed Echo: Every attack has a 20% chance to repeat itself.',
    'Fading Crescent': 'Deals more damage with fewer abilities left.',
    'Vampiric Touch': 'Heal 5% of enemy HP on kill.',
    'Unholy Fortitude': 'Damage taken is converted into temporary HP.',
    'Will of the Forgotten': 'The fewer abilities left, the stronger you get.',
    'Spectral Chain': 'Attacks link enemies, sharing damage.',
    'Chrono Echo': 'Increases the duration of all buffs.',
    'Time Dilation': 'The lower your health, the slower time moves.',
    'Revenants Stride': 'Lose speed but gain attack power per sacrifice.',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playMusic();
    unlockedAbilities = PlayerProgressManager.getUnlockedAbilities();
  }

  Future<void> _playMusic() async {
    await _audioPlayer.play(AssetSource('music/mystical-winds.mp3'),
        volume: 0.5);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(height: 20),

              // ✅ XP Bar at the top
              XPBar(),

              SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: unlockedAbilities.length,
                  itemBuilder: (context, index) {
                    if (index >= unlockedAbilities.length) {
                      print(
                          "⚠️ Invalid index: $index, available: ${unlockedAbilities.length}");
                      return SizedBox();
                    }

                    String ability = unlockedAbilities[index];
                    return _buildAbilityTile(ability);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "${selectedAbilities.length}/$maxAbilities Abilities Selected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey<String>(selectedAbilities.isNotEmpty
                            ? selectedAbilities.last
                            : "Select an ability"),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          selectedAbilities.isNotEmpty
                              ? abilities[selectedAbilities.last] ??
                                  "Select an ability"
                              : "Select an ability",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'MyCustomFont'),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // ✅ Confirm Selection Button (Always Enabled)
                    ElevatedButton(
                      onPressed: () => _confirmSelection(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAbilities.isEmpty
                            ? Colors.grey
                            : Colors.white,
                        foregroundColor: selectedAbilities.isEmpty
                            ? Colors.black45
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Confirm Selection"),
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityTile(String ability) {
    bool isUnlocked = unlockedAbilities.contains(ability);

    return GestureDetector(
      onTap: isUnlocked
          ? () => _toggleAbilitySelection(ability)
          : null, // Prevent selecting locked abilities
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: selectedAbilities.contains(ability)
                  ? Colors.green
                  : isUnlocked
                      ? Colors.blueGrey
                      : Colors.grey.shade800, // Grayed out if locked
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedAbilities.contains(ability)
                    ? Colors.greenAccent
                    : isUnlocked
                        ? Colors.white
                        : Colors.grey.shade600, // Dim border if locked
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.4, // Dim locked abilities
                child: Image.asset(
                  'assets/images/${ability.toLowerCase().replaceAll(" ", "_")}.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.help_outline,
                        size: 32, color: Colors.white);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAbilitySelection(String ability) {
    setState(() {
      if (selectedAbilities.contains(ability)) {
        selectedAbilities.remove(ability);
      } else if (selectedAbilities.length < maxAbilities) {
        selectedAbilities.add(ability);
      }
    });
  }

  void _confirmSelection() {
    print("✅ Selected Abilities: $selectedAbilities");
    widget.onAbilitiesSelected(selectedAbilities);
  }
}
