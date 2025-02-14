import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/inventory/inventory.dart';
import 'package:whisper_warriors/game/main.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      // Load inventory and other game data
      await InventoryStorage.loadInventory();
      final equippedItems = await InventoryManager.getEquippedItems();

      if (mounted) {
        // Create game with default abilities and equipped items
        final game = RogueShooterGame(
          selectedAbilities: [
            'BasicAttack',
            'DashAbility',
            'ShieldAbility',
          ],
          equippedItems: equippedItems,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameWidget.controlled(
              gameFactory: () => game,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Error loading game: $e");
      // You might want to show an error dialog here
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading game...'),
          ],
        ),
      ),
    );
  }
}
