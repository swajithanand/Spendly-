import '../models/inventory_item.dart';
import '../models/transaction_model.dart';

/// Decides which spendings are things that end up in the home, and what
/// kind of inventory item they become.
class InventoryRules {
  InventoryRules._();

  static const _electronicsWords = [
    'electronic', 'gadget', 'phone', 'laptop', 'tablet', 'tv', 'television',
    'charger', 'cable', 'headphone', 'earbud', 'speaker', 'camera', 'monitor',
    'keyboard', 'mouse', 'printer', 'router', 'battery', 'console', 'watch',
    'fridge', 'refrigerator', 'washer', 'washing machine', 'dryer', 'oven',
    'microwave', 'ac', 'air conditioner', 'heater', 'purifier', 'vacuum',
    'mixer', 'blender', 'appliance', 'fan', 'bulb', 'lamp',
  ];

  static bool _mentions(String text, List<String> words) {
    for (final w in words) {
      if (RegExp('\\b${RegExp.escape(w)}(?:s|es)?\\b').hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// The inventory kind a transaction suggests, or null when the spending
  /// is not a physical thing kept at home (rent, dining out, subscriptions…).
  static InventoryKind? kindFor(TransactionModel tx) =>
      kindForLabel(tx.label, tx.subcategory);

  static InventoryKind? kindForLabel(String label, String subcategory) {
    final text = label.trim().toLowerCase();
    switch (subcategory) {
      case 'Groceries':
        return InventoryKind.food;
      case 'Health':
        // Medicine and vitamins are stock; a doctor or gym visit is not.
        return _mentions(text, const [
          'pharmacy', 'pharmacies', 'medicine', 'vitamin', 'tablet', 'pill',
          'syrup', 'supplement', 'first aid',
        ])
            ? InventoryKind.medicine
            : null;
    }
    if (_mentions(text, _electronicsWords)) return InventoryKind.electronics;
    return subcategory == 'Shopping' ? InventoryKind.household : null;
  }

  /// A sensible starting name for the item made from [tx].
  static String nameFor(TransactionModel tx) {
    final label = tx.label.trim();
    if (label.isNotEmpty) return label;
    return tx.subcategory.isNotEmpty ? tx.subcategory : 'Purchase';
  }
}
