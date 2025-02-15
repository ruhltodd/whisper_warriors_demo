import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/items.dart';

class InventoryStorage {
  static const String fileName = 'inventory.json';
  static const int maxSlots = 20; // ✅ Define maximum inventory slots

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<List<InventoryItem>> loadInventory() async {
    try {
      print('📂 Loading inventory...');
      final file = await _localFile;

      if (!await file.exists()) {
        print('⚠️ No inventory file found, returning empty list');
        return [];
      }

      final String contents = await file.readAsString();
      print('📄 Raw inventory contents: $contents');

      final List<dynamic> jsonList = json.decode(contents);
      List<InventoryItem> items = [];

      for (var itemData in jsonList) {
        final Item? item = Item.createByName(itemData['name'] as String);
        if (item != null) {
          print('✅ Loading item: ${item.name}');
          // Initialize the item with its default stats
          switch (item.name.toLowerCase()) {
            case 'umbral fang':
              item.stats = {
                "Attack Speed": 0.15,
                "Pierce": 1.0,
              };
              break;
            case 'veil of the forgotten':
              item.stats = {
                "Defense Bonus": 0.50,
                "Spirit Bonus": 0.25,
              };
              break;
            case 'shard of umbrathos':
              item.stats = {
                "Spirit Multiplier": 0.35,
                "Dark Power": 0.25,
              };
              break;
          }

          items.add(InventoryItem(
            item: item,
            isEquipped: itemData['isEquipped'] as bool? ?? false,
            isNew: itemData['isNew'] as bool? ?? true,
            quantity: itemData['quantity'] as int? ?? 1,
          ));
        }
      }

      print('📦 Loaded ${items.length} items');
      return items;
    } catch (e) {
      print('❌ Error loading inventory: $e');
      return [];
    }
  }

  static Future<void> saveInventory(List<InventoryItem> items) async {
    // ✅ Remove duplicates by keeping only one copy of each item
    final Map<String, InventoryItem> uniqueItems = {};

    for (var item in items) {
      uniqueItems[item.item.name] =
          item; // Overwrites duplicates, keeping the latest one
    }

    // Convert map values to a list and enforce maxSlots limit
    final List<InventoryItem> deduplicatedItems = uniqueItems.values.toList();

    if (deduplicatedItems.length > maxSlots) {
      print(
          '⚠️ Inventory exceeds max slots ($maxSlots). Some items may be lost!');
      deduplicatedItems.removeRange(maxSlots, deduplicatedItems.length);
    }

    final file = await _localFile;
    final List<Map<String, dynamic>> jsonList = deduplicatedItems
        .map((item) => {
              'name': item.item.name,
              'isEquipped': item.isEquipped,
              'isNew': item.isNew,
              'quantity': item.quantity,
            })
        .toList();

    await file.writeAsString(json.encode(jsonList));
    print('💾 Saved ${deduplicatedItems.length} unique items to inventory');
  }

  static Future<List<InventoryItem>> loadEquippedItems() async {
    final allItems = await loadInventory();
    return allItems.where((item) => item.isEquipped).toList();
  }

  static Future<bool> hasOpenSlot() async {
    final inventory = await loadInventory();
    return inventory.length < maxSlots;
  }

  static Future<void> debugInventory() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        print('\n📦 Current Inventory File Contents:');
        print(const JsonEncoder.withIndent('  ').convert(jsonDecode(contents)));
      } else {
        print('\n📦 No inventory file exists yet');
      }
    } catch (e) {
      print('⚠️ Error debugging inventory: $e');
    }
  }
}
