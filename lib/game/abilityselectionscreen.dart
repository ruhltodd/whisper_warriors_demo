import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ Audio support
import 'main.dart';

class AbilitySelectionScreen extends StatefulWidget {
  final Function(List<String>) onAbilitiesSelected;

  AbilitySelectionScreen({required this.onAbilitiesSelected, Key? key})
      : super(key: key);

  @override
  _AbilitySelectionScreenState createState() => _AbilitySelectionScreenState();
}

class _AbilitySelectionScreenState extends State<AbilitySelectionScreen> {
  List<String> selectedAbilities = [];
  final int maxAbilities = 1;
  late AudioPlayer _audioPlayer; // ✅ Background music instance

  final Map<String, String> abilities = {
    'Whispering Flames':
        'Whispering Flames - A fire aura that burns enemies near you.',
    'Soul Fracture':
        'Soul Fracture - Enemies explode into ghostly shrapnel on death.',
    'Fading Crescent':
        'Fading Crescent - Deals more damage with fewer abilities left.',
    'Vampiric Touch': 'Vampiric Touch - Heal 5% of enemy HP on kill.',
    'Unholy Fortitude':
        'Unholy Fortitude - Damage taken is converted into temporary HP.',
    'Will of the Forgotten':
        'Will of the Forgotten - The fewer abilities left, the stronger you get.',
    'Spectral Chain': 'Spectral Chain - Attacks link enemies, sharing damage.',
    'Chrono Echo': 'Chrono Echo - Increases the duration of all buffs.',
    'Time Dilation':
        'Time Dilation - The lower your health, the slower time moves.',
    'Revenants Stride':
        'Revenants Stride - Lose speed but gain attack power per sacrifice.',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playMusic();
  }

  Future<void> _playMusic() async {
    await _audioPlayer.play(AssetSource('music/mystical-winds.mp3'),
        volume: 0.5);
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // ✅ Cleanup audio when leaving the screen
    super.dispose();
  }

/*  void _skipSelection() {
    print("⏭ Skipping Ability Selection. Loading Game...");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: GameWidget(
            game: RogueShooterGame(), // ✅ Start without selected abilities
          ),
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // ✅ Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_background.png',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              SizedBox(height: 40),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10, // ✅ 10 Columns
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    if (index < abilities.keys.length) {
                      String ability = abilities.keys.elementAt(index);
                      return _buildAbilityTile(ability);
                    } else {
                      return _buildEmptySlot();
                    }
                  },
                ),
              ),

              // ✅ Ability Selection Counter
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

                    // ✅ Confirm Selection Button (Only enabled when 10 abilities are selected)
                    ElevatedButton(
                      onPressed: selectedAbilities.length == maxAbilities
                          ? () => _confirmSelection()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
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
    return GestureDetector(
      onTap: () => _toggleAbilitySelection(ability),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: selectedAbilities.contains(ability)
                  ? Colors.green
                  : Colors.blueGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedAbilities.contains(ability)
                    ? Colors.greenAccent
                    : Colors.white,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/images/${ability.toLowerCase().replaceAll(" ", "_")}.png',
                width: 48, // ✅ Smaller Icon
                height: 48, // ✅ Smaller Icon
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.help_outline,
                      size: 32, color: Colors.white);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white30,
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(Icons.lock, size: 32, color: Colors.white30), // Placeholder
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
    print("✅ Selected Abilities: $selectedAbilities"); // 🔍 Debugging
    widget.onAbilitiesSelected(selectedAbilities); // ✅ Send abilities to MyApp
  }
}
