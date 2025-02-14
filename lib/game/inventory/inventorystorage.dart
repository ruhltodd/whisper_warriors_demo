import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_warriors/game/inventory/inventoryitem.dart';
import 'package:whisper_warriors/game/items/itemfactory.dart';

class InventoryStorage {
  static const String fileName = 'inventory.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<void> saveInventory(List<InventoryItem> items) async {
    try {
      final file = await _localFile;
      final data = items
          .map((item) => {
                'name': item.item.name,
                'quantity': item.quantity,
                'isEquipped': item.isEquipped,
                'isNew': item.isNew,
                'stats': item.item.stats,
                'rarity': item.item.rarity.toString(),
                'expValue': item.item.expValue,
              })
          .toList();

      print('💾 Saving inventory:');
      print(const JsonEncoder.withIndent('  ').convert(data));

      await file.writeAsString(jsonEncode(data));
      print('✅ Inventory saved successfully');
    } catch (e) {
      print('❌ Error saving inventory: $e');
    }
  }

  static Future<List<InventoryItem>> loadInventory() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        print('📝 No inventory file found, starting fresh');
        return [];
      }

      final contents = await file.readAsString();
      print('📖 Loading inventory:');
      print(const JsonEncoder.withIndent('  ').convert(jsonDecode(contents)));

      final List<dynamic> data = jsonDecode(contents);
      return data.map((json) {
        final item = ItemFactory.createItem(json['name']);

        // Apply saved stats and properties
        if (json['stats'] != null) {
          item.stats = Map<String, double>.from(json['stats']);
        }

        return InventoryItem(
          item: item,
          quantity: json['quantity'] ?? 1,
          isEquipped: json['isEquipped'] ?? false,
          isNew: json['isNew'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('⚠️ Error loading inventory: $e');
      return [];
    }
  }

  static Future<List<InventoryItem>> loadEquippedItems() async {
    final allItems = await loadInventory();
    return allItems.where((item) => item.isEquipped).toList();
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
