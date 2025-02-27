import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';
import 'package:whisper_warriors/game/ui/globalexperiencelevelbar.dart';
import 'package:whisper_warriors/game/ui/itemframe.dart';
import 'package:whisper_warriors/game/ui/textstyles.dart';

const String INVENTORY_BOX_NAME = 'inventory_items';

class InventoryScreen extends StatefulWidget {
  final List<InventoryItem> availableItems;
  final Function(List<InventoryItem>) onConfirm;

  InventoryScreen({
    required this.availableItems,
    required this.onConfirm,
  });

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> selectedItems = [];
  InventoryItem? _hoveredItem; // Tracks hovered item for stats

  @override
  void initState() {
    super.initState();
    // Initialize with empty selection instead of equipped items
    selectedItems = [];
    print('🎮 Inventory opened with no pre-selected items');
  }

  Future<void> _confirmSelection() async {
    try {
      // Update equipped status for all items
      final updatedItems = widget.availableItems.map((item) {
        item.isEquipped = selectedItems
            .any((selected) => selected.item.name == item.item.name);
        return item;
      }).toList();

      // Save the updated inventory
      await InventoryStorage.saveInventory(updatedItems);
      print('✅ Saved equipped items state');

      // Call the confirmation callback
      widget.onConfirm(selectedItems);
    } catch (e) {
      print('❌ Error saving equipped items: $e');
    }
  }

  void _toggleItemSelection(InventoryItem item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.legendary:
        return Colors.orange;
      case ItemRarity.uncommon:
        return Colors.green;
      case ItemRarity.common:
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalGridSpaces = 16;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Add "Inventory" text to top right
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              "Inventory",
              style: GameTextStyles.gameTitle(
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 100),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: totalGridSpaces,
                  itemBuilder: (context, index) {
                    if (index < widget.availableItems.length) {
                      return _buildItemTile(widget.availableItems[index]);
                    } else {
                      return _buildLockedItemTile();
                    }
                  },
                ),
              ),
              // Selected items slots (3 slots)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    if (index < selectedItems.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
                              'assets/images/${selectedItems[index].item.name.toLowerCase().replaceAll(" ", "_")}.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
              GlobalExperienceLevelBar(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(200, 50),
                ),
                child: const Text(
                  "Confirm Selection",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
          // Back button in bottom left
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hoveredItem != null) _buildHoverStats(),
        ],
      ),
    );
  }

  Widget _buildLockedItemTile() {
    return Container(
      width: 48,
      height: 48,
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
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(InventoryItem item) {
    bool isSelected = selectedItems.contains(item);
    Color borderColor = _getRarityColor(item.item.rarity);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItem = item),
      onExit: (_) => setState(() => _hoveredItem = null),
      child: GestureDetector(
        onTap: () => _toggleItemSelection(item),
        child: AnimatedItemFrame(
          rarityColor: borderColor,
          child: Opacity(
            opacity: isSelected ? 0.5 : 1,
            child: Image.asset(
              'assets/images/${item.item.name.toLowerCase().replaceAll(" ", "_")}.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  /// Floating Hover Stats
  Widget _buildHoverStats() {
    if (_hoveredItem == null) return const SizedBox.shrink();

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
              _hoveredItem!.item.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _hoveredItem!.item.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hoveredItem!.item.stats.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _hoveredItem!.item.stats.toString(),
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
