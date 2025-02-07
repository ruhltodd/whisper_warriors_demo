import 'package:flutter/material.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';

class InventoryScreen extends StatefulWidget {
  final List<InventoryItem> availableItems;
  final Function(List<InventoryItem>) onConfirm;

  InventoryScreen({required this.availableItems, required this.onConfirm});

  @override
  _InventorySelectionScreenState createState() =>
      _InventorySelectionScreenState();
}

class _InventorySelectionScreenState extends State<InventoryScreen> {
  List<InventoryItem?> _selectedItems = List.filled(5, null);
  InventoryItem? _hoveredItem; // ✅ Tracks hovered item for stats

  void _toggleItemSelection(InventoryItem item) {
    setState(() {
      int firstEmptyIndex = _selectedItems.indexWhere((slot) => slot == null);

      if (_selectedItems.contains(item)) {
        _selectedItems[_selectedItems.indexOf(item)] = null;
      } else if (firstEmptyIndex != -1) {
        _selectedItems[firstEmptyIndex] = item;
      }
    });
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
                  "${_selectedItems.where((item) => item != null).length}/5 Items Selected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildConfirmButton(),
              const SizedBox(height: 20),
            ],
          ),
          if (_hoveredItem != null) _buildHoverStats(),
        ],
      ),
    );
  }

  /// ✅ **Equipped Slots**
  Widget _buildEquippedSlots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedItems[index] = null;
            });
          },
          child: Container(
            width: 64,
            height: 64,
            margin: EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _selectedItems[index] != null
                  ? Colors.grey[800]
                  : Colors.black45,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedItems[index] != null
                ? Image.asset(
                    'assets/images/${_selectedItems[index]!.item.name.toLowerCase().replaceAll(" ", "_")}.png',
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.lock, color: Colors.white54, size: 30),
          ),
        );
      }),
    );
  }

  /// ✅ **Inventory Grid with Hover Effect**
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
          bool isSelected = _selectedItems.contains(item);

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredItem = item),
            onExit: (_) => setState(() => _hoveredItem = null),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  _toggleItemSelection(item);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.grey : Colors.white,
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

  /// ✅ **Floating Hover Stats**
  Widget _buildHoverStats() {
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ..._hoveredItem!.item.stats.entries.map((stat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  "${stat.key}: ${(stat.value * 100).toStringAsFixed(0)}%", // Convert to percentage if needed
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// ✅ **Confirm Button**
  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: () {
        widget.onConfirm(_selectedItems.whereType<InventoryItem>().toList());
      },
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
