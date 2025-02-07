import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/player/player.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';

class InventoryBar extends StatelessWidget {
  final Player player;

  const InventoryBar({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<InventoryItem>>(
      valueListenable: player.equippedItemsNotifier, // ✅ Listen for updates
      builder: (context, equippedItems, _) {
        print(
            "🛡 Updated Equipped Items: ${equippedItems.map((item) => item.item.name).toList()}");

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            children: equippedItems.map((inventoryItem) {
              return _buildItemIcon(inventoryItem);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildItemIcon(InventoryItem inventoryItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8), // ✅ Makes the icon rounded
        child: Image.asset(
          'assets/images/${inventoryItem.item.name.toLowerCase().replaceAll(" ", "_")}.png',
          width: 32,
          height: 32,
          fit:
              BoxFit.cover, // ✅ Ensures the image fits within the rounded frame
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              backgroundColor:
                  Colors.white.withOpacity(0.2), // ✅ Placeholder background
              radius: 16,
              child: Icon(Icons.category,
                  size: 20,
                  color: Colors.white), // ✅ Generic item icon fallback
            );
          },
        ),
      ),
    );
  }
}
