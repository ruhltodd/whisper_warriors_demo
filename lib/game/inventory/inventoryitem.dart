import 'package:hive/hive.dart';
import 'package:whisper_warriors/game/items/items.dart'; // ✅ Import items.dart to access Item class
import 'package:whisper_warriors/game/player/player.dart'; // ✅ Import Player to access stats modification
import 'package:whisper_warriors/game/abilities/abilities.dart'; // Add this import

part 'inventoryitem.g.dart'; // ✅ Ensure this is included

@HiveType(typeId: 0) // ✅ Assign a unique type ID
class InventoryItem extends HiveObject {
  @HiveField(0)
  final Item item; // ✅ Store an Item instance

  @HiveField(1)
  bool isEquipped; // ✅ Tracks whether item is equipped

  InventoryItem({
    required this.item,
    this.isEquipped = false,
  }) {
    // Remove the automatic save from constructor
    // this.save(); // This line was causing the error
  }

  // Add a method to safely add the item to inventory
  static Future<InventoryItem> create({
    required Item item,
    bool isEquipped = false,
  }) async {
    final box = Hive.box<InventoryItem>('inventoryBox');
    final inventoryItem = InventoryItem(
      item: item,
      isEquipped: isEquipped,
    );

    // Add to box with the item's name as key
    await box.put(item.name, inventoryItem);
    return inventoryItem;
  }

  // Add this method to ensure state is properly loaded
  void ensureStateIsSaved() {
    if (!isInBox) {
      save();
    }
  }

  /// ✅ **Getter Methods to Access `Item` Properties**
  String get name => item.name; // ✅ Retrieve from item
  String get description => item.description; // ✅ Retrieve from item
  String get rarity => item.rarity; // ✅ Retrieve from item
  Map<String, double> get stats => item.stats; // ✅ Retrieve from item

  @override
  void applyEffect(Player player) {
    // Apply the base effects (e.g., modifying attack speed, defense, etc.)
    item.stats.forEach((key, value) {
      switch (key) {
        case "Attack Speed":
          player.baseAttackSpeed *= (1 + value);
          break;
        case "Piercing":
          player.hasUmbralFang = true;
          break;
        case "Defense Bonus":
          if (player.currentHealth <= player.maxHealth * 0.5) {
            player.baseDefense *= (1 + value);
          }
          break;
        case "Spirit Multiplier":
          player.spiritMultiplier *= (1 + value);
          break;
        default:
          print("⚠️ Unknown stat: $key");
      }
    });

    print("🎭 Applied ${item.name} to Player.");

    // Ensure WhisperingFlames is added **AFTER** the Player is mounted
    Future.delayed(Duration(milliseconds: 100), () {
      if (player.isMounted && player.gameRef != null) {
        if (!player.gameRef.children
            .any((child) => child is WhisperingFlames)) {
          player.gameRef.add(WhisperingFlames());
          print("🔥 WhisperingFlames applied to Player!");
        } else {
          print("🔥 WhisperingFlames already active.");
        }
      } else {
        print("⚠️ Cannot add WhisperingFlames: player is not mounted yet.");
      }
    });
  }

  // ✅ Remove effects when unequipped
  void removeEffect(Player player) {
    item.stats.forEach((key, value) {
      // ✅ Explicit reference to `item.stats`
      switch (key) {
        case "Attack Speed":
          player.baseAttackSpeed /= (1 + value);
          break;
        case "Piercing":
          player.hasUmbralFang = false;
          break;
        case "Defense Bonus":
          player.baseDefense /= (1 + value);
          break;
        case "Spirit Multiplier":
          player.spiritMultiplier /= (1 + value);
          break;
        default:
          print("⚠️ Unknown stat: $key");
      }
    });
    print("⛔ Removed ${item.name} effects.");
  }

  // Modify toggleEquip to be more robust
  void toggleEquip(Player player) {
    isEquipped = !isEquipped;

    if (isEquipped) {
      applyEffect(player);
    } else {
      removeEffect(player);
    }

    // Ensure the state change is saved
    ensureStateIsSaved();
    save();
    print("🔄 ${item.name} equipped state changed to: $isEquipped");
  }
}
