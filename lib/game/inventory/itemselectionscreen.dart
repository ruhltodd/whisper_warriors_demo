import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/inventory/inventorystorage.dart';
import 'package:whisper_warriors/game/items/itemrarity.dart';

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
          Column(
            children: [
              const SizedBox(height: 40),
              Text(
                "Select Your Equipment",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildEquippedSlots(),
              const SizedBox(height: 20),
              Expanded(child: _buildInventoryGrid()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "${selectedItems.length}/5 Items Selected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildConfirmButton(context),
              const SizedBox(height: 20),
            ],
          ),
          if (_hoveredItem != null) _buildHoverStats(),
        ],
      ),
    );
  }

  /// Equipped Slots
  Widget _buildEquippedSlots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        // Safely check if we have an item at this index
        final hasItemAtIndex = index < widget.availableItems.length;

        return GestureDetector(
          onTap: () {
            if (!hasItemAtIndex) return; // Don't do anything if no item exists
            setState(() {
              selectedItems.removeWhere((item) =>
                  item.item.name == widget.availableItems[index].item.name);
            });
          },
          child: Container(
            width: 64,
            height: 64,
            margin: EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: hasItemAtIndex &&
                      selectedItems.any((item) =>
                          item.item.name ==
                          widget.availableItems[index].item.name)
                  ? Colors.grey[800]
                  : Colors.black45,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: hasItemAtIndex &&
                    selectedItems.any((item) =>
                        item.item.name ==
                        widget.availableItems[index].item.name)
                ? Image.asset(
                    'assets/images/${widget.availableItems[index].item.name.toLowerCase().replaceAll(" ", "_")}.png',
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.lock, color: Colors.white54, size: 30),
          ),
        );
      }),
    );
  }

  /// Inventory Grid with Hover Effect
  Widget _buildInventoryGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: widget.availableItems.length,
        itemBuilder: (context, index) {
          InventoryItem item = widget.availableItems[index];
          bool isSelected = selectedItems.contains(item);
          Color borderColor = _getRarityColor(item.item.rarity);

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredItem = item),
            onExit: (_) => setState(() => _hoveredItem = null),
            child: GestureDetector(
              onTap: () => _toggleItemSelection(item),
              child: Container(
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
        },
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

  /// Confirm Button
  Widget _buildConfirmButton(BuildContext context) {
    return ElevatedButton(
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
    );
  }
}
