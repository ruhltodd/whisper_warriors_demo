import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:whisper_warriors/game/inventory/playerprogressmanager.dart';
import 'package:whisper_warriors/game/ui/globalexperiencelevelbar.dart'; // ✅ Added for ability unlocks
import 'package:whisper_warriors/game/ui/textstyles.dart';

class AbilitySelectionScreen extends StatefulWidget {
  final Function(List<String>) onAbilitiesSelected;

  AbilitySelectionScreen({required this.onAbilitiesSelected, Key? key})
      : super(key: key);

  @override
  _AbilitySelectionScreenState createState() => _AbilitySelectionScreenState();
}

class _AbilitySelectionScreenState extends State<AbilitySelectionScreen> {
  List<String> selectedAbilities = [];
  final int maxAbilities = 3;
  late AudioPlayer _audioPlayer;
  late List<String> unlockedAbilities; // ✅ Store unlocked abilities
  String? _hoveredAbility; // Add this to track hovered ability

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
    await _audioPlayer.play(AssetSource('audio/mystical-winds.mp3'),
        volume: 0.5);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalGridSpaces = 16;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        // Center the constrained box
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 820, // Lock width to 820px
            maxHeight: 820, // Lock height to 820px
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/main_menu_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Text(
                  "Abilities",
                  style: GameTextStyles.gameTitle(
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Column(
                children: [
                  SizedBox(height: 100), // Space for hover stats
                  // Available abilities grid
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: totalGridSpaces,
                      itemBuilder: (context, index) {
                        if (index < unlockedAbilities.length) {
                          return _buildAbilityTile(unlockedAbilities[index]);
                        } else {
                          return _buildLockedAbilityTile();
                        }
                      },
                    ),
                  ),
                  // Selected abilities grid (3 slots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        if (index < selectedAbilities.length) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/images/${selectedAbilities[index].toLowerCase().replaceAll(" ", "_")}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.shade600,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                  // Experience bar
                  GlobalExperienceLevelBar(),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
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
                  ),
                  SizedBox(height: 10),
                ],
              ),
              if (_hoveredAbility != null) _buildHoverStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbilityTile(String ability) {
    bool isUnlocked = unlockedAbilities.contains(ability);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAbility = ability),
      onExit: (_) => setState(() => _hoveredAbility = null),
      child: GestureDetector(
        onTap: isUnlocked ? () => _toggleAbilitySelection(ability) : null,
        child: Container(
          width: 48, // Explicit width
          height: 48, // Explicit height
          decoration: BoxDecoration(
            color: selectedAbilities.contains(ability)
                ? Colors.green
                : isUnlocked
                    ? Colors.blueGrey
                    : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedAbilities.contains(ability)
                  ? Colors.greenAccent
                  : isUnlocked
                      ? Colors.white
                      : Colors.grey.shade600,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0), // Reduced padding
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.4,
              child: Image.asset(
                'assets/images/${ability.toLowerCase().replaceAll(" ", "_")}.png',
                width: 40, // Slightly smaller to account for padding
                height: 40, // Slightly smaller to account for padding
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.help_outline,
                      size: 24, color: Colors.white);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedAbilityTile() {
    return Container(
      width: 48, // Explicit width
      height: 48, // Explicit height
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade600,
          width: 2,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.4,
          child: Icon(
            Icons.lock,
            color: Colors.grey.shade400,
            size: 24, // Smaller icon size
          ),
        ),
      ),
    );
  }

  Widget _buildHoverStats() {
    if (_hoveredAbility == null) return const SizedBox.shrink();

    return Positioned(
      left: 410 -
          120, // Half of 820px (constrained width) - half of hover box width
      top: 20,
      child: Container(
        width: 240,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _hoveredAbility!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              abilities[_hoveredAbility!] ?? '',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    print("✅ Confirming ability selection...");
    print("✅ Selected Abilities: $selectedAbilities");

    if (selectedAbilities.isEmpty) {
      print("❌ No abilities selected!");
      return;
    }

    print("✅ Calling onAbilitiesSelected callback...");
    widget.onAbilitiesSelected(selectedAbilities);
    print("✅ Callback completed");
  }
}
