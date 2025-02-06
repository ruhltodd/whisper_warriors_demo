import 'package:flutter/material.dart';
import 'inventoryitem.dart';

class InventoryScreen extends StatefulWidget {
  final void Function(List<InventoryItem>)
      onConfirm; // ✅ Waits for confirmation
  final List<InventoryItem> availableItems;
  final Function(InventoryItem) onItemSelected; // Add onItemSelected here

  InventoryScreen({
    required this.onConfirm,
    required this.availableItems,
    required this.onItemSelected, // Add to constructor
  });

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Select Your Equipment"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.availableItems.length,
              itemBuilder: (context, index) {
                final item = widget.availableItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedItems.contains(item)) {
                        selectedItems.remove(item);
                      } else if (selectedItems.length < 5) {
                        selectedItems.add(item);
                      }
                    });

                    // Trigger the onItemSelected callback here
                    widget.onItemSelected(
                        item); // Pass selected item to the callback
                  },
                  child: Card(
                    color: selectedItems.contains(item)
                        ? Colors.blueGrey[700]
                        : Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          item.description,
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ Confirm button (Game starts only after confirmation)
          if (selectedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  // When the confirm button is pressed,
                  // pass the list of selected items to the onConfirm callback.
                  widget.onConfirm(selectedItems);
                },
                child: Text("Confirm Selection"),
              ),
            )
        ],
      ),
    );
  }
}
