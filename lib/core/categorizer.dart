import '../models/transaction_model.dart';

/// Keyword-based smart categorizer. Given a free-text label like "milk" or
/// "Netflix", suggests a subcategory such as "Groceries" or "Subscriptions".
/// User history takes priority: if the user previously assigned the same
/// label to a subcategory, that assignment is reused.
class SmartCategorizer {
  SmartCategorizer._();

  static const Map<String, List<String>> _keywords = {
    'Groceries': [
      'milk', 'cheese', 'bread', 'egg', 'butter', 'yogurt', 'veggie',
      'vegetable', 'fruit', 'meat', 'chicken', 'fish', 'rice', 'flour',
      'grocer', 'grocery', 'groceries', 'supermarket', 'market', 'walmart', 'costco', 'aldi',
      'kroger', 'bigbasket', 'snack', 'cereal',
    ],
    'Dining': [
      'restaurant', 'coffee', 'cafe', 'pizza', 'burger', 'lunch', 'dinner',
      'breakfast', 'takeout', 'take-out', 'starbucks', 'mcdonald', 'kfc',
      'swiggy', 'zomato', 'doordash', 'ubereats', 'food delivery', 'bar',
    ],
    'Transport': [
      'gas', 'fuel', 'petrol', 'diesel', 'uber', 'lyft', 'ola', 'taxi',
      'cab', 'bus', 'train', 'metro', 'parking', 'toll', 'car wash',
    ],
    'Utilities': [
      'electricity', 'electric bill', 'water bill', 'internet', 'wifi',
      'broadband', 'phone', 'mobile', 'utility', 'sewage', 'trash',
    ],
    'Housing': [
      'rent', 'mortgage', 'maintenance', 'repair', 'furniture', 'lease',
    ],
    'Subscriptions': [
      'spotify', 'netflix', 'prime', 'hulu', 'disney', 'youtube',
      'subscription', 'icloud', 'apple music', 'hbo', 'membership',
    ],
    'Entertainment': [
      'cinema', 'movie', 'concert', 'game', 'vinyl', 'theater', 'theatre',
      'show', 'ticket', 'festival',
    ],
    'Health': [
      'pharmacy', 'pharmacies', 'medicine', 'doctor', 'dentist', 'gym', 'fitness',
      'hospital', 'clinic', 'therapy', 'vitamin',
    ],
    'Shopping': [
      'clothes', 'clothing', 'shoes', 'amazon', 'mall', 'electronics',
      'gadget', 'gift', 'flipkart', 'ikea',
    ],
    'Travel': [
      'travel', 'travelling', 'traveling', 'flight', 'hotel', 'airbnb', 'trip', 'vacation', 'holiday',
      'visa', 'luggage',
    ],
    'Investments': [
      'vanguard', 'stock', 'mutual fund', 'sip', 'etf', 'crypto',
      'investment', 'brokerage', 'fidelity', '401k', 'ira',
    ],
    'Savings': [
      'emergency', 'deposit', 'saving', 'fd', 'piggy',
    ],
    'Education': [
      'course', 'book', 'tuition', 'udemy', 'coursera', 'school', 'class',
    ],
  };

  /// All subcategory names the categorizer knows about, for pickers.
  static List<String> get subcategories => _keywords.keys.toList();

  /// Default emoji for each built-in subcategory.
  static const Map<String, String> emojis = {
    'Groceries': '🛒',
    'Dining': '🍽️',
    'Transport': '🚗',
    'Utilities': '💡',
    'Housing': '🏠',
    'Subscriptions': '📺',
    'Entertainment': '🎬',
    'Health': '💊',
    'Shopping': '🛍️',
    'Travel': '✈️',
    'Investments': '📈',
    'Savings': '🐷',
    'Education': '📚',
  };

  /// Suggests a subcategory for [label]. Checks the user's [history] first
  /// (most recent transaction with the same normalized label wins), then
  /// falls back to keyword matching. Returns '' when nothing matches.
  static String suggest(String label, [List<TransactionModel> history = const []]) {
    final norm = label.trim().toLowerCase();
    if (norm.isEmpty) return '';

    for (var i = history.length - 1; i >= 0; i--) {
      final t = history[i];
      if (t.subcategory.isNotEmpty && t.label.trim().toLowerCase() == norm) {
        return t.subcategory;
      }
    }

    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (kw.contains(' ') ? norm.contains(kw) : _containsWord(norm, kw)) {
          return entry.key;
        }
      }
    }
    return '';
  }

  /// Whole-word match so "gas" matches "gas station" but not "vegas", and
  /// "bar" does not match "barber". A plural ending is allowed ("egg" →
  /// "eggs", "bus" → "buses").
  static bool _containsWord(String text, String kw) {
    return RegExp('\\b${RegExp.escape(kw)}(?:s|es)?\\b').hasMatch(text);
  }
}
