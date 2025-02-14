import 'package:whisper_warriors/game/items/items.dart';

class ItemFactory {
  static Item createItem(String name) {
    switch (name) {
      case 'Umbral Fang':
        return UmbralFang();
      case 'Veil of the Forgotten':
        return VeilOfTheForgotten();
      case 'Shard of Umbrathos':
        return ShardOfUmbrathos();
      // Add other items as needed
      default:
        throw ArgumentError('Unknown item: $name');
    }
  }
}
