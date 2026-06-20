import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../core/categorizer.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/currencies.dart';

class UserProfile {
  String name;
  String email;
  String currency;

  UserProfile({
    this.name = 'Alex Morgan',
    this.email = '',
    this.currency = 'USD',
  });
}

class DraftTx {
  String amount;
  String? categoryId;
  String label;
  String subcategory;
  bool subcatManual; // user picked a subcategory; stop auto-suggesting
  DateTime? date;
  String? editingId; // non-null when editing an existing transaction

  DraftTx({
    this.amount = '0',
    this.categoryId,
    this.label = '',
    this.subcategory = '',
    this.subcatManual = false,
    this.date,
    this.editingId,
  });
}

class AppState extends ChangeNotifier {
  // Auth
  bool signedIn = false;
  bool isOnboarding = true;
  UserProfile user = UserProfile();

  // Budget
  double income = 4800;
  List<CategoryModel> categories = [];

  // Transactions
  List<TransactionModel> transactions = [];

  // User-created subcategories (shown alongside the built-in ones)
  List<String> customSubcategories = [];

  // Transaction draft
  DraftTx draft = DraftTx();

  // Navigation
  int activeTab = 0;

  // Activity tab
  String activityPeriod = 'month';
  DateTime? activityFrom;
  DateTime? activityTo;

  // Insights tab
  String insightsPeriod = 'month';
  DateTime? insightsFrom;
  DateTime? insightsTo;
  String? insightsSelectedCatId;

  AppState() {
    _load();
  }

  // ── Persistence ─────────────────────────────────────────

  static const _kIncome = 'income';
  static const _kCategories = 'categories';
  static const _kTransactions = 'transactions';
  static const _kCustomSubcats = 'customSubcategories';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final incomeVal = prefs.getDouble(_kIncome);
    final catsJson = prefs.getString(_kCategories);
    final txsJson = prefs.getString(_kTransactions);
    customSubcategories = prefs.getStringList(_kCustomSubcats) ?? [];

    if (incomeVal != null && catsJson != null && txsJson != null) {
      income = incomeVal;
      categories = (jsonDecode(catsJson) as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      transactions = (jsonDecode(txsJson) as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _migrateSubcategories();
    } else {
      _applyPreset(0);
      _seedDemo();
    }
    notifyListeners();
  }

  /// Backfills subcategories for transactions saved before smart
  /// categorization existed.
  void _migrateSubcategories() {
    var changed = false;
    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      if (t.subcategory.isEmpty) {
        final sub = SmartCategorizer.suggest(t.label);
        if (sub.isNotEmpty) {
          transactions[i] = t.copyWith(subcategory: sub);
          changed = true;
        }
      }
    }
    if (changed) _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kIncome, income);
    await prefs.setString(
        _kCategories, jsonEncode(categories.map((c) => c.toJson()).toList()));
    await prefs.setString(
        _kTransactions, jsonEncode(transactions.map((t) => t.toJson()).toList()));
    await prefs.setStringList(_kCustomSubcats, customSubcategories);
  }

  // ── Auth ────────────────────────────────────────────────

  void signIn({required String email, String name = ''}) {
    signedIn = true;
    isOnboarding = true;
    user.email = email;
    if (name.isNotEmpty) user.name = name;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    isOnboarding = true;
    notifyListeners();
  }

  void completeSetup() {
    isOnboarding = false;
    notifyListeners();
  }

  // ── Budget ──────────────────────────────────────────────

  void applyPreset(int index) {
    _applyPreset(index);
    _save();
    notifyListeners();
  }

  void _applyPreset(int index) {
    categories = AppConstants.presets[index].categories.map((c) => c.clone()).toList();
  }

  int get totalPct => categories.fold(0, (s, c) => s + c.pct);

  void setIncome(double v) {
    income = v;
    _save();
    notifyListeners();
  }

  void addCategory() {
    if (categories.length >= 8) return;
    final used = categories.map((c) => c.color).toList();
    final color = _nextColor(used);
    final rem = (100 - totalPct).clamp(0, 100);
    categories.add(CategoryModel(name: 'New category', pct: rem, color: color));
    _save();
    notifyListeners();
  }

  void removeCategory(String id) {
    if (categories.length <= 1) return;
    categories.removeWhere((c) => c.id == id);
    _save();
    notifyListeners();
  }

  void updateCategoryName(String id, String name) {
    _cat(id)?.name = name;
    _save();
    notifyListeners();
  }

  void updateCategoryPct(String id, int pct) {
    _cat(id)?.pct = pct.clamp(0, 100);
    _save();
    notifyListeners();
  }

  void updateCategoryColor(String id, Color color) {
    _cat(id)?.color = color;
    _save();
    notifyListeners();
  }

  CategoryModel? _cat(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Color _nextColor(List<Color> used) {
    for (final c in AppColors.palette) {
      if (!used.contains(c)) return c;
    }
    return AppColors.palette[used.length % AppColors.palette.length];
  }

  // ── Transactions ────────────────────────────────────────

  void saveTransaction() {
    final amt = _parseMoney(draft.amount);
    if (amt <= 0 || draft.categoryId == null) return;
    if (draft.editingId != null) {
      final i = transactions.indexWhere((t) => t.id == draft.editingId);
      if (i == -1) return;
      transactions[i] = transactions[i].copyWith(
        amount: amt,
        categoryId: draft.categoryId,
        label: draft.label,
        subcategory: draft.subcategory,
        createdAt: draft.date,
      );
    } else {
      transactions.add(TransactionModel(
        amount: amt,
        categoryId: draft.categoryId!,
        label: draft.label,
        subcategory: draft.subcategory,
        createdAt: draft.date,
      ));
    }
    _save();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  double _parseMoney(String s) =>
      double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  // ── Draft ───────────────────────────────────────────────

  void openDraft({String? categoryId}) {
    draft = DraftTx(categoryId: categoryId ?? categories.firstOrNull?.id);
    notifyListeners();
  }

  void openDraftForEdit(TransactionModel tx) {
    draft = DraftTx(
      amount: _formatAmount(tx.amount),
      categoryId: tx.categoryId,
      label: tx.label,
      subcategory: tx.subcategory,
      subcatManual: tx.subcategory.isNotEmpty,
      date: tx.createdAt,
      editingId: tx.id,
    );
    notifyListeners();
  }

  String _formatAmount(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  void draftKeyPress(String k) {
    var v = draft.amount;
    if (k == 'del') {
      v = v.length > 1 ? v.substring(0, v.length - 1) : '0';
    } else if (k == '.') {
      if (!v.contains('.')) v = '$v.';
    } else {
      if (v == '0') {
        v = k;
      } else {
        if (v.contains('.') && v.split('.')[1].length >= 2) return;
        v = '$v$k';
      }
    }
    draft.amount = v;
    notifyListeners();
  }

  void draftSetCategory(String id) {
    draft.categoryId = id;
    notifyListeners();
  }

  void draftSetLabel(String v) {
    draft.label = v;
    if (!draft.subcatManual) {
      draft.subcategory = SmartCategorizer.suggest(v, transactions);
    }
    notifyListeners();
  }

  void draftSetSubcategory(String s) {
    // Tapping the already-selected chip clears it (back to auto).
    if (draft.subcategory == s) {
      draft.subcatManual = false;
      draft.subcategory = SmartCategorizer.suggest(draft.label, transactions);
    } else {
      draft.subcategory = s;
      draft.subcatManual = true;
    }
    notifyListeners();
  }

  /// Built-in + user-created subcategory names, for pickers.
  List<String> get allSubcategories =>
      [...SmartCategorizer.subcategories, ...customSubcategories];

  /// Adds a user-defined subcategory (if new) and selects it in the draft.
  /// Returns the canonical name, or null when the input is empty.
  String? addCustomSubcategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final existing = allSubcategories.where(
        (s) => s.toLowerCase() == trimmed.toLowerCase());
    final canonical = existing.isNotEmpty ? existing.first : trimmed;
    if (existing.isEmpty) {
      customSubcategories.add(trimmed);
      _save();
    }
    draft.subcategory = canonical;
    draft.subcatManual = true;
    notifyListeners();
    return canonical;
  }

  void draftSetDate(DateTime d) {
    final old = draft.date ?? DateTime.now();
    draft.date = DateTime(d.year, d.month, d.day, old.hour, old.minute);
    notifyListeners();
  }

  bool get draftIsValid {
    final amt = _parseMoney(draft.amount);
    return amt > 0 && draft.categoryId != null;
  }

  // ── Navigation ──────────────────────────────────────────

  void setTab(int i) {
    activeTab = i;
    notifyListeners();
  }

  // ── Filtering ───────────────────────────────────────────

  List<TransactionModel> filtered(String period, {DateTime? from, DateTime? to}) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return transactions.where((t) => !t.createdAt.isBefore(start)).toList();
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        return transactions.where((t) => !t.createdAt.isBefore(start)).toList();
      case 'year':
        final start = DateTime(now.year, 1, 1);
        return transactions.where((t) => !t.createdAt.isBefore(start)).toList();
      case 'custom':
        if (from != null && to != null) {
          final s = DateTime(from.year, from.month, from.day);
          final e = DateTime(to.year, to.month, to.day, 23, 59, 59);
          return transactions
              .where((t) => !t.createdAt.isBefore(s) && !t.createdAt.isAfter(e))
              .toList();
        }
        return transactions;
      default:
        return List.from(transactions);
    }
  }

  double monthSpentForCat(String catId) => filtered('month')
      .where((t) => t.categoryId == catId)
      .fold(0.0, (s, t) => s + t.amount);

  // ── Insights period setters ─────────────────────────────

  void setActivityPeriod(String p) {
    activityPeriod = p;
    if (p != 'custom') { activityFrom = null; activityTo = null; }
    notifyListeners();
  }

  void setActivityRange(DateTime from, DateTime to) {
    activityFrom = from;
    activityTo = to;
    notifyListeners();
  }

  void setInsightsPeriod(String p) {
    insightsPeriod = p;
    if (p != 'custom') { insightsFrom = null; insightsTo = null; }
    notifyListeners();
  }

  void setInsightsRange(DateTime from, DateTime to) {
    insightsFrom = from;
    insightsTo = to;
    notifyListeners();
  }

  void setInsightsCat(String id) {
    insightsSelectedCatId = id;
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────

  void updateProfile({String? name, String? email, String? currency}) {
    if (name != null) user.name = name;
    if (email != null) user.email = email;
    if (currency != null) user.currency = currency;
    notifyListeners();
  }

  String get userInitials {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get firstName {
    final first = user.name.trim().split(RegExp(r'\s+'))[0];
    return first.isEmpty ? 'spender' : first.toLowerCase();
  }

  String get currencySymbol => Currencies.symbolFor(user.currency);

  // ── Seed data ───────────────────────────────────────────

  void _seedDemo() {
    final now = DateTime.now();
    String id(String name) {
      try {
        return categories.firstWhere((c) => c.name == name).id;
      } catch (_) {
        return categories.first.id;
      }
    }

    final samples = [
      (cat: 'Needs',   label: 'Milk',        amt: 4.20,   d: 0,  h: 9),
      (cat: 'Needs',   label: 'Veggies',     amt: 18.40,  d: 0,  h: 18),
      (cat: 'Wants',   label: 'Coffee',      amt: 5.75,   d: 0,  h: 8),
      (cat: 'Needs',   label: 'Bread',       amt: 6.50,   d: 1,  h: 10),
      (cat: 'Wants',   label: 'Spotify',     amt: 11.99,  d: 1,  h: 12),
      (cat: 'Needs',   label: 'Meat',        amt: 24.30,  d: 2,  h: 17),
      (cat: 'Wants',   label: 'Restaurant',  amt: 46.20,  d: 3,  h: 20),
      (cat: 'Needs',   label: 'Internet',    amt: 65.00,  d: 6,  h: 10),
      (cat: 'Savings', label: 'Vanguard',    amt: 400.00, d: 7,  h: 11),
      (cat: 'Needs',   label: 'Electricity', amt: 92.40,  d: 8,  h: 12),
      (cat: 'Wants',   label: 'Vinyl',       amt: 28.00,  d: 9,  h: 15),
      (cat: 'Wants',   label: 'Cinema',      amt: 32.00,  d: 10, h: 21),
      (cat: 'Needs',   label: 'Rent',        amt: 1450.0, d: 12, h: 9),
      (cat: 'Wants',   label: 'Restaurant',  amt: 38.50,  d: 13, h: 19),
      (cat: 'Savings', label: 'Emergency',   amt: 150.00, d: 16, h: 10),
      (cat: 'Wants',   label: 'Netflix',     amt: 15.49,  d: 22, h: 11),
      (cat: 'Needs',   label: 'Gas',         amt: 48.00,  d: 23, h: 14),
      // last month
      (cat: 'Needs',   label: 'Rent',        amt: 1450.0, d: 40, h: 9),
      (cat: 'Savings', label: 'Vanguard',    amt: 400.00, d: 50, h: 11),
      (cat: 'Wants',   label: 'Concert',     amt: 85.00,  d: 52, h: 19),
      (cat: 'Needs',   label: 'Internet',    amt: 65.00,  d: 47, h: 10),
      // 2-3 months
      (cat: 'Needs',   label: 'Rent',        amt: 1450.0, d: 75, h: 9),
      (cat: 'Savings', label: 'Vanguard',    amt: 400.00, d: 80, h: 11),
      (cat: 'Wants',   label: 'Travel',      amt: 240.00, d: 110, h: 13),
    ];

    for (final s in samples) {
      final ts = DateTime(now.year, now.month, now.day, s.h)
          .subtract(Duration(days: s.d));
      transactions.add(TransactionModel(
        amount: s.amt,
        categoryId: id(s.cat),
        label: s.label,
        subcategory: SmartCategorizer.suggest(s.label),
        createdAt: ts,
      ));
    }
  }
}
