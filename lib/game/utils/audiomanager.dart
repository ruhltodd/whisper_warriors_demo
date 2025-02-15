import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  late final AudioPlayer _bgmPlayer;
  late final AudioPlayer _gameOverPlayer;

  bool _isMusicMuted = false;
  bool _isSoundMuted = false;
  double _musicVolume = 0.5; // Default volume of 0.5
  double _soundVolume = 0.5; // Default volume of 0.5

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _bgmPlayer = AudioPlayer();
    _gameOverPlayer = AudioPlayer();
  }

  // Background music methods
  Future<void> playBackgroundMusic(String filename) async {
    if (!_isMusicMuted) {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setSource(AssetSource(filename));
      await _bgmPlayer.setVolume(_musicVolume);
      await _bgmPlayer.resume();
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      if (_bgmPlayer.state == PlayerState.playing) {
        await _bgmPlayer.stop();
      }
    } catch (e) {
      print('❌ Error stopping background music: $e');
    }
  }

  void pauseBackgroundMusic() {
    _bgmPlayer.pause();
  }

  void resumeBackgroundMusic() {
    if (!_isMusicMuted) {
      _bgmPlayer.resume();
    }
  }

  // Sound effect methods
  Future<void> playSound(String filename) async {
    if (!_isSoundMuted) {
      await FlameAudio.play(filename, volume: _soundVolume);
    }
  }

  // Volume control methods
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _bgmPlayer.setVolume(_musicVolume);
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
  }

  // Mute control methods
  void toggleMusicMute() {
    _isMusicMuted = !_isMusicMuted;
    if (_isMusicMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  void toggleSoundMute() {
    _isSoundMuted = !_isSoundMuted;
  }

  // Getters for current state
  bool get isMusicMuted => _isMusicMuted;
  bool get isSoundMuted => _isSoundMuted;
  double get musicVolume => _musicVolume;
  double get soundVolume => _soundVolume;

  // Preload audio files
  Future<void> preloadAudio() async {
    await FlameAudio.audioCache.loadAll([
      'soft_etheral.mp3',
      'game_over.mp3',
      // Add other audio files here
    ]);
  }

  Future<void> playGameOverMusic() async {
    try {
      // Stop background music first
      await stopBackgroundMusic();

      // Set up and play game over music
      await _gameOverPlayer.setSource(AssetSource('game_over.mp3'));
      await _gameOverPlayer.setVolume(_musicVolume);
      await _gameOverPlayer.setReleaseMode(ReleaseMode.stop); // Don't loop
      await _gameOverPlayer.play(AssetSource('game_over.mp3'));
    } catch (e) {
      print('❌ Error playing game over music: $e');
    }
  }

  // Cleanup method
  void dispose() {
    _bgmPlayer.dispose();
    _gameOverPlayer.dispose();
  }
}
