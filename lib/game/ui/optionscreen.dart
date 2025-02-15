import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/utils/audiomanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisper_warriors/game/ui/textstyles.dart';

class OptionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const OptionsScreen({
    required this.onBack,
    Key? key,
  }) : super(key: key);

  @override
  _OptionsScreenState createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  late final AudioManager _audioManager;
  double _musicVolume = 0.5;
  double _soundVolume = 0.5;
  bool _isMusicMuted = false;
  bool _isSoundMuted = false;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble('musicVolume') ?? 0.5;
      _soundVolume = prefs.getDouble('soundVolume') ?? 0.5;
      _isMusicMuted = prefs.getBool('isMusicMuted') ?? false;
      _isSoundMuted = prefs.getBool('isSoundMuted') ?? false;

      // Apply loaded settings to AudioManager
      _audioManager.setMusicVolume(_musicVolume);
      _audioManager.setSoundVolume(_soundVolume);
      if (_isMusicMuted) _audioManager.toggleMusicMute();
      if (_isSoundMuted) _audioManager.toggleSoundMute();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setDouble('soundVolume', _soundVolume);
    await prefs.setBool('isMusicMuted', _isMusicMuted);
    await prefs.setBool('isSoundMuted', _isSoundMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Options Content
          Center(
            child: Container(
              width: 500,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Options',
                    style: GameTextStyles.gameTitle(fontSize: 32),
                  ),
                  SizedBox(height: 40),

                  // Music Volume Control
                  _buildVolumeControl(
                    'Music Volume',
                    _musicVolume,
                    _isMusicMuted,
                    (value) {
                      setState(() {
                        _musicVolume = value;
                        _audioManager.setMusicVolume(value);
                        _saveSettings();
                      });
                    },
                    () {
                      setState(() {
                        _isMusicMuted = !_isMusicMuted;
                        _audioManager.toggleMusicMute();
                        _saveSettings();
                      });
                    },
                  ),

                  SizedBox(height: 20),

                  // Sound Effects Volume Control
                  _buildVolumeControl(
                    'Sound Effects',
                    _soundVolume,
                    _isSoundMuted,
                    (value) {
                      setState(() {
                        _soundVolume = value;
                        _audioManager.setSoundVolume(value);
                        _saveSettings();
                      });
                    },
                    () {
                      setState(() {
                        _isSoundMuted = !_isSoundMuted;
                        _audioManager.toggleSoundMute();
                        _saveSettings();
                      });
                    },
                  ),

                  SizedBox(height: 40),

                  // Back Button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: GameTextStyles.gameTitle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(
    String label,
    double value,
    bool isMuted,
    ValueChanged<double> onChanged,
    VoidCallback onMuteToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GameTextStyles.gameTitle(fontSize: 20),
            ),
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: onMuteToggle,
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: isMuted ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
