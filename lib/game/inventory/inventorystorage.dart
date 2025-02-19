import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/items.dart';
import 'dart:io'; // Keep this import
import 'package:path_provider/path_provider.dart'; // Keep this import

class InventoryStorage {
  static const String fileName = 'inventory.json';
  static const int maxSlots = 20; // ✅ Define max inventory slots

  static Future<List<InventoryItem>> loadInventory() async {
    try {
      print('📂 Loading inventory...');

      String contents;

      if (kIsWeb) {
        // ✅ Web: Use SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        contents = prefs.getString(fileName) ?? '[]';
      } else {
        // ✅ Mobile/Desktop: Use file storage
        final file = await _localFile;
        if (file == null || !file.existsSync()) {
          print('⚠️ No inventory file found, returning empty list');
          return [];
        }
        contents = await file.readAsString();
      }

      print('📄 Raw inventory contents: $contents');

      final List<dynamic> jsonList = json.decode(contents);
      List<InventoryItem> items = [];

      for (var itemData in jsonList) {
        final Item? item = Item.createByName(itemData['name'] as String);
        if (item != null) {
          print('✅ Loading item: ${item.name}');
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
    final Map<String, InventoryItem> uniqueItems = {};
    for (var item in items) {
      uniqueItems[item.item.name] = item; // ✅ Remove duplicates
    }

    final List<InventoryItem> deduplicatedItems = uniqueItems.values.toList();
    if (deduplicatedItems.length > maxSlots) {
      print(
          '⚠️ Inventory exceeds max slots ($maxSlots). Some items may be lost!');
      deduplicatedItems.removeRange(maxSlots, deduplicatedItems.length);
    }

    final List<Map<String, dynamic>> jsonList = deduplicatedItems
        .map((item) => {
              'name': item.item.name,
              'isEquipped': item.isEquipped,
              'isNew': item.isNew,
              'quantity': item.quantity,
            })
        .toList();

    final jsonString = json.encode(jsonList);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(fileName, jsonString);
    } else {
      final file = await _localFile;
      if (file != null) await file.writeAsString(jsonString);
    }

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
      String contents;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        contents = prefs.getString(fileName) ?? '[]';
      } else {
        final file = await _localFile;
        if (file == null || !file.existsSync()) {
          print('\n📦 No inventory file exists yet');
          return;
        }
        contents = await file.readAsString();
      }

      print('\n📦 Current Inventory File Contents:');
      print(const JsonEncoder.withIndent('  ').convert(jsonDecode(contents)));
    } catch (e) {
      print('⚠️ Error debugging inventory: $e');
    }
  }

  // Only use this function on Mobile/Desktop
  static Future<File?> get _localFile async {
    if (kIsWeb) {
      print("⚠️  Not using file storage on Web.");
      return null; // Web doesn't use file storage
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path; // Access path here
      return File(
          '$path/$fileName'); // Use string interpolation to create the file path
    } catch (e) {
      print('❌ Error getting local file: $e');
      return null;
    }
  }
}
