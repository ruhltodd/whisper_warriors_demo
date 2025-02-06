import 'package:hive/hive.dart';
import 'fireaura.dart';
import 'items.dart'; // ✅ Import items.dart to access Item class
import 'player.dart'; // ✅ Import Player to access stats modification

part 'inventoryitem.g.dart'; // ✅ Ensure this is included

@HiveType(typeId: 0) // ✅ Assign a unique type ID
class InventoryItem extends HiveObject {
  @HiveField(0)
  final Item item; // ✅ Store an Item instance

  @HiveField(1)
  bool isEquipped; // ✅ Tracks whether item is equipped

  InventoryItem({required this.item, this.isEquipped = false});

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

    // Ensure FireAura is added **AFTER** the Player is mounted
    Future.delayed(Duration(milliseconds: 100), () {
      if (player.isMounted && player.gameRef != null) {
        if (!player.gameRef.children.any((child) => child is FireAura)) {
          player.gameRef.add(FireAura(player: player));
          print("🔥 FireAura applied to Player!");
        } else {
          print("🔥 FireAura already active.");
        }
      } else {
        print("⚠️ Cannot add FireAura: player is not mounted yet.");
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

  // ✅ Equip or Unequip the item
  void toggleEquip(Player player) {
    if (isEquipped) {
      removeEffect(player);
    } else {
      applyEffect(player);
    }
    isEquipped = !isEquipped;
    save(); // ✅ Save change to Hive
  }
}
