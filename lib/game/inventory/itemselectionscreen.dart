import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';
import 'package:whisper_warriors/game/ui/globalexperiencelevelbar.dart';
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
    // Initialize with already equipped items
    selectedItems =
        widget.availableItems.where((item) => item.isEquipped).toList();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
              SizedBox(height: 100), // Space for hover stats
              // Available items grid
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
              // XP Bar
              XPBar(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
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

    // Debug prints
    print('🔍 Hovered item: ${_hoveredItem!.item.name}');
    print('📊 Raw stats: ${_hoveredItem!.item.stats}');
    print('🔢 Stats entries count: ${_hoveredItem!.item.stats.entries.length}');
    print('📝 Stats display: ${_hoveredItem!.getStatsDisplay()}');

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 120,
      top: MediaQuery.of(context).size.height / 2 - 160,
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
                color: _getRarityColor(_hoveredItem!.item.rarity),
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
            const SizedBox(height: 8),
            // Stats section with explicit check
            if (_hoveredItem!.item.stats.isNotEmpty) ...[
              ..._hoveredItem!.item.stats.entries.map((stat) {
                String displayValue = (stat.value * 100).toStringAsFixed(0);
                String prefix = stat.value >= 0 ? "+" : "";
                print('🎯 Adding stat: ${stat.key} = $prefix$displayValue%');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "$prefix$displayValue% ${stat.key}",
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
