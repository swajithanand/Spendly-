import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/inventory_item.dart';
import '../core/inventory_rules.dart';
import '../models/transaction_model.dart';
import '../core/categorizer.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/currencies.dart';
import '../core/money.dart';

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
  String paySchedule = 'Monthly';
  String cycleStart = '1st';
  List<CategoryModel> categories = [];

  // Transactions
  List<TransactionModel> transactions = [];

  // User-created subcategories (shown alongside the built-in ones)
  List<String> customSubcategories = [];

  // Emoji chosen for user-created subcategories (name → emoji)
  Map<String, String> customSubcatEmojis = {};

  // Home inventory: things kept at home, and purchases the user said they
  // would add details for later.
  List<InventoryItem> inventory = [];
  List<PendingInventory> pendingInventory = [];

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

  /// False until saved data has been read from disk.
  bool loaded = false;

  /// Set when some saved data could not be read. The unreadable text is
  /// kept on disk under a `corruptBackup_` key instead of being overwritten.
  String? loadError;

  /// True once the user has finished onboarding on this device.
  bool setupDone = false;

  /// Ids of the sample transactions seeded on first launch.
  Set<String> demoTxIds = {};

  /// Completes when the initial load has finished.
  late final Future<void> ready;

  AppState() {
    ready = _load();
  }

  // ── Persistence ─────────────────────────────────────────

  static const _kSignedIn = 'signedIn';
  static const _kSetupDone = 'setupDone';
  static const _kDemoTxIds = 'demoTxIds';
  static const _kInventory = 'inventory';
  static const _kPendingInventory = 'pendingInventory';
  static const _kIncome = 'income';
  static const _kCategories = 'categories';
  static const _kTransactions = 'transactions';
  static const _kCustomSubcats = 'customSubcategories';
  static const _kCustomSubcatEmojis = 'customSubcatEmojis';
  static const _kUserName = 'userName';
  static const _kUserEmail = 'userEmail';
  static const _kUserCurrency = 'userCurrency';
  static const _kPaySchedule = 'paySchedule';
  static const _kCycleStart = 'cycleStart';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final corrupt = <String, String>{};

      // Decodes the JSON stored under [key]. Unreadable text is set aside
      // (not thrown away) and null is returned.
      T? decode<T>(String key, T Function(dynamic json) parse) {
        final raw = prefs.getString(key);
        if (raw == null) return null;
        try {
          return parse(jsonDecode(raw));
        } catch (_) {
          corrupt[key] = raw;
          return null;
        }
      }

      signedIn = prefs.getBool(_kSignedIn) ?? false;
      setupDone = prefs.getBool(_kSetupDone) ?? false;
      isOnboarding = !setupDone;
      demoTxIds = (prefs.getStringList(_kDemoTxIds) ?? []).toSet();
      customSubcategories = prefs.getStringList(_kCustomSubcats) ?? [];
      customSubcatEmojis = decode(_kCustomSubcatEmojis,
              (j) => Map<String, String>.from(j as Map)) ??
          {};
      user.name = prefs.getString(_kUserName) ?? user.name;
      user.email = prefs.getString(_kUserEmail) ?? user.email;
      user.currency = prefs.getString(_kUserCurrency) ?? user.currency;
      paySchedule = prefs.getString(_kPaySchedule) ?? paySchedule;
      cycleStart = prefs.getString(_kCycleStart) ?? cycleStart;
      income = prefs.getDouble(_kIncome) ?? income;
      inventory = decode(
              _kInventory,
              (j) => (j as List)
                  .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
                  .toList()) ??
          [];
      pendingInventory = decode(
              _kPendingInventory,
              (j) => (j as List)
                  .map((e) =>
                      PendingInventory.fromJson(e as Map<String, dynamic>))
                  .toList()) ??
          [];

      final hasSavedBudget = prefs.containsKey(_kCategories) ||
          prefs.containsKey(_kTransactions);
      final cats = decode(
          _kCategories,
          (j) => (j as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList());
      final txs = decode(
          _kTransactions,
          (j) => (j as List)
              .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList());

      if (!hasSavedBudget) {
        // First launch.
        _applyPreset(0);
        _seedDemo();
      } else {
        if (cats != null && cats.isNotEmpty) {
          categories = cats;
        } else {
          _applyPreset(0);
        }
        transactions = txs ?? [];
        _migrateSubcategories();
      }

      if (corrupt.isNotEmpty) {
        for (final e in corrupt.entries) {
          await prefs.setString('corruptBackup_${e.key}', e.value);
        }
        loadError = 'Some saved data could not be read. '
            'A backup copy was kept on this device.';
      }
    } catch (_) {
      // Storage itself is unavailable: run on defaults for this session.
      if (categories.isEmpty) _applyPreset(0);
      loadError = 'Saved data could not be opened.';
    }
    loaded = true;
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

  bool _dirty = false;
  Future<void>? _saving;

  /// Queues a save. Writes never overlap and never start before the initial
  /// load has finished; changes made while a write is in flight are folded
  /// into one follow-up write.
  Future<void> _save() {
    _dirty = true;
    return _saving ??= _flush();
  }

  Future<void> _flush() async {
    try {
      await ready;
      final prefs = await SharedPreferences.getInstance();
      while (_dirty) {
        _dirty = false;
        // Snapshot everything first so one write is internally consistent.
        final catsJson = jsonEncode(categories.map((c) => c.toJson()).toList());
        final txsJson =
            jsonEncode(transactions.map((t) => t.toJson()).toList());
        final emojisJson = jsonEncode(customSubcatEmojis);
        final inventoryJson =
            jsonEncode(inventory.map((i) => i.toJson()).toList());
        final pendingJson =
            jsonEncode(pendingInventory.map((p) => p.toJson()).toList());
        final subcats = List<String>.of(customSubcategories);
        final demoIds = demoTxIds.toList();
        final snapshot = (
          signedIn: signedIn,
          setupDone: setupDone,
          income: income,
          name: user.name,
          email: user.email,
          currency: user.currency,
          paySchedule: paySchedule,
          cycleStart: cycleStart,
        );
        await prefs.setBool(_kSignedIn, snapshot.signedIn);
        await prefs.setBool(_kSetupDone, snapshot.setupDone);
        await prefs.setDouble(_kIncome, snapshot.income);
        await prefs.setString(_kCategories, catsJson);
        await prefs.setString(_kTransactions, txsJson);
        await prefs.setStringList(_kDemoTxIds, demoIds);
        await prefs.setString(_kInventory, inventoryJson);
        await prefs.setString(_kPendingInventory, pendingJson);
        await prefs.setStringList(_kCustomSubcats, subcats);
        await prefs.setString(_kCustomSubcatEmojis, emojisJson);
        await prefs.setString(_kUserName, snapshot.name);
        await prefs.setString(_kUserEmail, snapshot.email);
        await prefs.setString(_kUserCurrency, snapshot.currency);
        await prefs.setString(_kPaySchedule, snapshot.paySchedule);
        await prefs.setString(_kCycleStart, snapshot.cycleStart);
      }
    } catch (_) {
      // A failed write must not crash the app; the next change retries.
    } finally {
      _saving = null;
    }
  }

  // ── Auth ────────────────────────────────────────────────

  void signIn({required String email, String name = ''}) {
    signedIn = true;
    isOnboarding = !setupDone;
    user.email = email;
    if (name.isNotEmpty) user.name = name;
    _save();
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    isOnboarding = true;
    _save();
    notifyListeners();
  }

  void completeSetup() {
    isOnboarding = false;
    setupDone = true;
    _save();
    notifyListeners();
  }

  // ── Budget ──────────────────────────────────────────────

  /// Replaces the categories with a preset. A new category that has the
  /// same name as an existing one keeps its id, so its transactions stay
  /// attached; see [orphansIfPresetApplied] for the ones that would not.
  void applyPreset(int index) {
    _applyPreset(index);
    _save();
    notifyListeners();
  }

  void _applyPreset(int index) {
    final oldIdByName = {
      for (final c in categories) c.name.trim().toLowerCase(): c.id
    };
    categories = AppConstants.presets[index].categories
        .map((c) => c.clone(id: oldIdByName[c.name.trim().toLowerCase()]))
        .toList();
  }

  /// How many transactions would be left without a category if preset
  /// [index] were applied now.
  int orphansIfPresetApplied(int index) {
    final keptNames = AppConstants.presets[index].categories
        .map((c) => c.name.trim().toLowerCase())
        .toSet();
    final keptIds = categories
        .where((c) => keptNames.contains(c.name.trim().toLowerCase()))
        .map((c) => c.id)
        .toSet();
    final currentIds = categories.map((c) => c.id).toSet();
    return transactions
        .where((t) =>
            currentIds.contains(t.categoryId) && !keptIds.contains(t.categoryId))
        .length;
  }

  // ── Uncategorized ───────────────────────────────────────

  /// Pseudo-category id for transactions whose category was deleted.
  static const uncategorizedId = '__uncategorized';

  bool hasCategory(String id) => categories.any((c) => c.id == id);

  /// Transactions in [txs] belonging to [catId]; [uncategorizedId] selects
  /// the ones whose category no longer exists.
  List<TransactionModel> txsForCat(List<TransactionModel> txs, String catId) {
    if (catId == uncategorizedId) {
      final ids = categories.map((c) => c.id).toSet();
      return txs.where((t) => !ids.contains(t.categoryId)).toList();
    }
    return txs.where((t) => t.categoryId == catId).toList();
  }

  // ── Budget cycle ────────────────────────────────────────

  /// Day of the month the budget cycle starts on.
  int get cycleStartDay => cycleStart == '15th' ? 15 : 1;

  /// First day of the budget cycle containing [now].
  DateTime cycleStartDate([DateTime? now]) {
    final n = now ?? DateTime.now();
    final day = cycleStartDay;
    return n.day >= day
        ? DateTime(n.year, n.month, day)
        : DateTime(n.year, n.month - 1, day);
  }

  /// First day of the cycle after the one containing [now].
  DateTime cycleEndDate([DateTime? now]) {
    final s = cycleStartDate(now);
    return DateTime(s.year, s.month + 1, s.day);
  }

  /// Human label for the current cycle: "November 2026" for calendar-month
  /// cycles, otherwise the date span ("Nov 15 – Dec 14").
  String cycleLabel([DateTime? now]) {
    final start = cycleStartDate(now);
    if (cycleStartDay == 1) return DateFormat('MMMM yyyy').format(start);
    final last = cycleEndDate(now).subtract(const Duration(days: 1));
    final f = DateFormat('MMM d');
    return '${f.format(start)} – ${f.format(last)}';
  }

  int get totalPct => categories.fold(0, (s, c) => s + c.pct);

  void setIncome(double v) {
    income = v;
    _save();
    notifyListeners();
  }

  void setPaySchedule(String v) {
    paySchedule = v;
    _save();
    notifyListeners();
  }

  void setCycleStart(String v) {
    cycleStart = v;
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

  void updateCategorySavings(String id, bool isSavings) {
    _cat(id)?.isSavings = isSavings;
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

  /// Saves the draft. Returns the transaction when a NEW one was created
  /// (null for an edit or an invalid draft), so the caller can offer
  /// follow-ups such as adding it to the home inventory.
  TransactionModel? saveTransaction() {
    final amt = _parseMoney(draft.amount);
    if (amt <= 0 || draft.categoryId == null) return null;
    TransactionModel? created;
    if (draft.editingId != null) {
      final i = transactions.indexWhere((t) => t.id == draft.editingId);
      if (i == -1) return null;
      transactions[i] = transactions[i].copyWith(
        amount: amt,
        categoryId: draft.categoryId,
        label: draft.label,
        subcategory: draft.subcategory,
        createdAt: draft.date,
      );
    } else {
      created = TransactionModel(
        amount: amt,
        categoryId: draft.categoryId!,
        label: draft.label,
        subcategory: draft.subcategory,
        createdAt: draft.date,
      );
      transactions.add(created);
    }
    _save();
    notifyListeners();
    return created;
  }

  // ── Home inventory ──────────────────────────────────────

  /// Adds [item]. If it came from a purchase that was waiting for details,
  /// that reminder is cleared.
  void addInventoryItem(InventoryItem item) {
    inventory.add(item);
    if (item.txId != null) {
      pendingInventory.removeWhere((p) => p.txId == item.txId);
    }
    _save();
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem item) {
    final i = inventory.indexWhere((x) => x.id == item.id);
    if (i == -1) return;
    inventory[i] = item;
    _save();
    notifyListeners();
  }

  InventoryItem? _lastDeletedItem;
  int _lastDeletedItemIndex = 0;

  void deleteInventoryItem(String id) {
    final i = inventory.indexWhere((x) => x.id == id);
    if (i == -1) return;
    _lastDeletedItem = inventory.removeAt(i);
    _lastDeletedItemIndex = i;
    _save();
    notifyListeners();
  }

  bool undoDeleteInventoryItem() {
    final item = _lastDeletedItem;
    if (item == null) return false;
    inventory.insert(_lastDeletedItemIndex.clamp(0, inventory.length), item);
    _lastDeletedItem = null;
    _save();
    notifyListeners();
    return true;
  }

  /// Changes an item's quantity by [delta], never going below zero.
  void adjustInventoryQuantity(String id, double delta) {
    final i = inventory.indexWhere((x) => x.id == id);
    if (i == -1) return;
    final q = (inventory[i].quantity + delta).clamp(0.0, double.infinity);
    inventory[i] = inventory[i].copyWith(quantity: q);
    _save();
    notifyListeners();
  }

  /// Remembers that [tx] still needs inventory details ("remind me later").
  void deferInventory(TransactionModel tx) {
    final kind = InventoryRules.kindFor(tx);
    if (pendingInventory.any((p) => p.txId == tx.id)) return;
    pendingInventory.add(PendingInventory(
      txId: tx.id,
      name: InventoryRules.nameFor(tx),
      kind: kind ?? InventoryKind.other,
      purchasedAt: tx.createdAt,
    ));
    _save();
    notifyListeners();
  }

  void dismissPendingInventory(String txId) {
    pendingInventory.removeWhere((p) => p.txId == txId);
    _save();
    notifyListeners();
  }

  /// Items that are overdue or due within a week, most urgent first.
  List<InventoryItem> inventoryAttention([DateTime? now]) {
    final list = inventory.where((i) {
      final s = i.status(now: now);
      return s == DueStatus.overdue || s == DueStatus.soon;
    }).toList()
      ..sort((a, b) => a.daysLeft(now)!.compareTo(b.daysLeft(now)!));
    return list;
  }

  /// Number of things on the Inventory tab that want the user's attention.
  int get inventoryBadgeCount =>
      inventoryAttention().length + pendingInventory.length;

  TransactionModel? _lastDeleted;
  int _lastDeletedIndex = 0;
  bool _lastDeletedWasDemo = false;
  PendingInventory? _lastDeletedPending;

  void deleteTransaction(String id) {
    final i = transactions.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _lastDeleted = transactions.removeAt(i);
    _lastDeletedIndex = i;
    _lastDeletedPending =
        pendingInventory.where((p) => p.txId == id).firstOrNull;
    pendingInventory.removeWhere((p) => p.txId == id);
    _lastDeletedWasDemo = demoTxIds.remove(id);
    _save();
    notifyListeners();
  }

  /// Puts back the most recently deleted transaction. Returns false when
  /// there is nothing to restore.
  bool undoDelete() {
    final tx = _lastDeleted;
    if (tx == null) return false;
    transactions.insert(_lastDeletedIndex.clamp(0, transactions.length), tx);
    if (_lastDeletedWasDemo) demoTxIds.add(tx.id);
    final pending = _lastDeletedPending;
    if (pending != null) pendingInventory.add(pending);
    _lastDeleted = null;
    _lastDeletedPending = null;
    _save();
    notifyListeners();
    return true;
  }

  // ── Sample data ─────────────────────────────────────────

  bool get hasDemoData => transactions.any((t) => demoTxIds.contains(t.id));

  /// Removes the sample transactions seeded on first launch, leaving
  /// everything the user entered.
  void clearDemoData() {
    transactions.removeWhere((t) => demoTxIds.contains(t.id));
    demoTxIds.clear();
    _lastDeleted = null;
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
      // A deleted category leaves nothing selected, so the user must pick.
      categoryId: hasCategory(tx.categoryId) ? tx.categoryId : null,
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
  String? addCustomSubcategory(String name, {String emoji = ''}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final existing = allSubcategories.where(
        (s) => s.toLowerCase() == trimmed.toLowerCase());
    final canonical = existing.isNotEmpty ? existing.first : trimmed;
    if (existing.isEmpty) {
      customSubcategories.add(trimmed);
    }
    if (emoji.isNotEmpty) customSubcatEmojis[canonical] = emoji;
    if (existing.isEmpty || emoji.isNotEmpty) _save();
    draft.subcategory = canonical;
    draft.subcatManual = true;
    notifyListeners();
    return canonical;
  }

  /// Emoji for a subcategory: user's choice first, then built-in default.
  String subcatEmoji(String name) =>
      customSubcatEmojis[name] ?? SmartCategorizer.emojis[name] ?? '🏷️';

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
        // The current budget cycle, which starts on [cycleStartDay].
        final start = cycleStartDate(now);
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
    _save();
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

  /// Amount formatter for the user's currency.
  MoneyFormat get money => MoneyFormat(user.currency);

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
      final tx = TransactionModel(
        amount: s.amt,
        categoryId: id(s.cat),
        label: s.label,
        subcategory: SmartCategorizer.suggest(s.label),
        createdAt: ts,
      );
      transactions.add(tx);
      demoTxIds.add(tx.id);
    }
  }
}
