import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/budget_status.dart';
import 'package:spendly/core/categorizer.dart';
import 'package:spendly/core/currencies.dart';
import 'package:spendly/core/csv_exporter.dart';
import 'package:spendly/models/category_model.dart';
import 'package:spendly/models/transaction_model.dart';
import 'package:spendly/state/app_state.dart';

/// Creates a fresh AppState backed by an empty SharedPreferences mock.
Future<AppState> makeState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  // Two microtask yields: one for _load()'s await on getInstance(),
  // one for notifyListeners() at the end of _load().
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return state;
}

void main() {
  // ── Initialization ──────────────────────────────────────────────────────────

  group('Initialization', () {
    test('default preset is 50/30/20 with three categories', () async {
      final s = await makeState();
      expect(s.categories.map((c) => c.name), ['Needs', 'Wants', 'Savings']);
      expect(s.categories.map((c) => c.pct), [50, 30, 20]);
    });

    test('demo transactions are seeded on first launch', () async {
      final s = await makeState();
      expect(s.transactions.length, greaterThan(0));
    });

    test('default income is 4800', () async {
      final s = await makeState();
      expect(s.income, 4800.0);
    });

    test('starts signed out with onboarding flag', () async {
      final s = await makeState();
      expect(s.signedIn, false);
      expect(s.isOnboarding, true);
    });

    test('totalPct sums to 100 on default preset', () async {
      final s = await makeState();
      expect(s.totalPct, 100);
    });
  });

  // ── Auth ────────────────────────────────────────────────────────────────────

  group('Auth', () {
    test('signIn sets signedIn and stores email', () async {
      final s = await makeState();
      s.signIn(email: 'test@example.com');
      expect(s.signedIn, true);
      expect(s.user.email, 'test@example.com');
    });

    test('signIn with name updates user name', () async {
      final s = await makeState();
      s.signIn(email: 'a@b.com', name: 'Jane Doe');
      expect(s.user.name, 'Jane Doe');
    });

    test('signIn without name keeps existing name', () async {
      final s = await makeState();
      s.signIn(email: 'a@b.com');
      expect(s.user.name, isNotEmpty);
    });

    test('signOut clears signedIn flag', () async {
      final s = await makeState();
      s.signIn(email: 'a@b.com');
      s.signOut();
      expect(s.signedIn, false);
      expect(s.isOnboarding, true);
    });

    test('completeSetup clears onboarding flag', () async {
      final s = await makeState();
      s.completeSetup();
      expect(s.isOnboarding, false);
    });
  });

  // ── Profile ─────────────────────────────────────────────────────────────────

  group('Profile', () {
    test('updateProfile changes name, email, currency', () async {
      final s = await makeState();
      s.updateProfile(name: 'Bob', email: 'bob@x.com', currency: 'EUR');
      expect(s.user.name, 'Bob');
      expect(s.user.email, 'bob@x.com');
      expect(s.user.currency, 'EUR');
    });

    test('userInitials — two-word name', () async {
      final s = await makeState();
      s.updateProfile(name: 'Alex Morgan');
      expect(s.userInitials, 'AM');
    });

    test('userInitials — single word', () async {
      final s = await makeState();
      s.updateProfile(name: 'Alex');
      expect(s.userInitials, 'A');
    });

    test('firstName returns lowercase first word', () async {
      final s = await makeState();
      s.updateProfile(name: 'Alex Morgan');
      expect(s.firstName, 'alex');
    });

    test('currencySymbol — USD', () async {
      final s = await makeState();
      s.updateProfile(currency: 'USD');
      expect(s.currencySymbol, '\$');
    });

    test('currencySymbol — EUR', () async {
      final s = await makeState();
      s.updateProfile(currency: 'EUR');
      expect(s.currencySymbol, '€');
    });

    test('currencySymbol — GBP', () async {
      final s = await makeState();
      s.updateProfile(currency: 'GBP');
      expect(s.currencySymbol, '£');
    });

    test('currencySymbol — INR', () async {
      final s = await makeState();
      s.updateProfile(currency: 'INR');
      expect(s.currencySymbol, '₹');
    });

    test('currencySymbol — unknown code falls back to the code itself', () async {
      final s = await makeState();
      s.updateProfile(currency: 'XYZ');
      expect(s.currencySymbol, 'XYZ');
    });

    test('currency catalog covers major world currencies', () {
      final codes = Currencies.all.map((c) => c.code).toSet();
      expect(codes.length, Currencies.all.length); // no duplicates
      for (final code in [
        'USD', 'EUR', 'GBP', 'INR', 'JPY', 'CNY', 'BRL', 'NGN', 'ZAR',
        'AED', 'KRW', 'IDR', 'MXN', 'TRY', 'PHP', 'VND', 'CAD', 'AUD',
      ]) {
        expect(codes, contains(code));
      }
      expect(Currencies.all.length, greaterThan(100));
    });

    test('symbolFor returns symbols and falls back to code', () {
      expect(Currencies.symbolFor('NGN'), '₦');
      expect(Currencies.symbolFor('KRW'), '₩');
      expect(Currencies.symbolFor('ZZZ'), 'ZZZ');
    });
  });

  // ── Budget ──────────────────────────────────────────────────────────────────

  group('Budget', () {
    test('setIncome updates income', () async {
      final s = await makeState();
      s.setIncome(6000);
      expect(s.income, 6000.0);
    });

    test('applyPreset 1 (70/20/10) switches categories', () async {
      final s = await makeState();
      s.applyPreset(1);
      expect(s.categories.map((c) => c.name), ['Living', 'Savings', 'Fun']);
      expect(s.categories.map((c) => c.pct), [70, 20, 10]);
    });

    test('applyPreset 2 (Zero-based) has 6 categories', () async {
      final s = await makeState();
      s.applyPreset(2);
      expect(s.categories.length, 6);
    });

    test('addCategory appends and fills remaining pct', () async {
      final s = await makeState();
      // Reduce a category to leave room
      s.updateCategoryPct(s.categories.last.id, 10);
      final before = s.categories.length;
      s.addCategory();
      expect(s.categories.length, before + 1);
    });

    test('addCategory is blocked at 8 categories', () async {
      final s = await makeState();
      s.applyPreset(2); // 6 cats
      s.addCategory();
      s.addCategory(); // 8
      s.addCategory(); // no-op
      expect(s.categories.length, 8);
    });

    test('removeCategory removes the specified category', () async {
      final s = await makeState();
      final id = s.categories.first.id;
      final before = s.categories.length;
      s.removeCategory(id);
      expect(s.categories.length, before - 1);
      expect(s.categories.any((c) => c.id == id), false);
    });

    test('removeCategory refuses to remove the last remaining category', () async {
      final s = await makeState();
      while (s.categories.length > 1) {
        s.removeCategory(s.categories.first.id);
      }
      s.removeCategory(s.categories.first.id); // should be no-op
      expect(s.categories.length, 1);
    });

    test('updateCategoryName changes name', () async {
      final s = await makeState();
      final id = s.categories.first.id;
      s.updateCategoryName(id, 'Groceries');
      expect(s.categories.first.name, 'Groceries');
    });

    test('updateCategoryPct clamps to 0', () async {
      final s = await makeState();
      final id = s.categories.first.id;
      s.updateCategoryPct(id, -5);
      expect(s.categories.first.pct, 0);
    });

    test('updateCategoryPct clamps to 100', () async {
      final s = await makeState();
      final id = s.categories.first.id;
      s.updateCategoryPct(id, 150);
      expect(s.categories.first.pct, 100);
    });

    test('updateCategoryColor changes color', () async {
      final s = await makeState();
      final id = s.categories.first.id;
      s.updateCategoryColor(id, Colors.red);
      expect(s.categories.first.color, Colors.red);
    });
  });

  // ── Transactions ─────────────────────────────────────────────────────────────

  group('Transactions', () {
    test('saveTransaction adds a transaction with correct amount', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('5');
      s.draftKeyPress('0');
      final before = s.transactions.length;
      s.saveTransaction();
      expect(s.transactions.length, before + 1);
      expect(s.transactions.last.amount, 50.0);
    });

    test('saveTransaction assigns the draft category', () async {
      final s = await makeState();
      s.openDraft();
      final catId = s.categories.last.id;
      s.draftSetCategory(catId);
      s.draftKeyPress('2');
      s.saveTransaction();
      expect(s.transactions.last.categoryId, catId);
    });

    test('saveTransaction is no-op when amount is 0', () async {
      final s = await makeState();
      s.openDraft();
      final before = s.transactions.length;
      s.saveTransaction();
      expect(s.transactions.length, before);
    });

    test('deleteTransaction removes by id', () async {
      final s = await makeState();
      final id = s.transactions.first.id;
      final before = s.transactions.length;
      s.deleteTransaction(id);
      expect(s.transactions.length, before - 1);
      expect(s.transactions.any((t) => t.id == id), false);
    });

    test('deleteTransaction with unknown id is a no-op', () async {
      final s = await makeState();
      final before = s.transactions.length;
      s.deleteTransaction('nonexistent-id');
      expect(s.transactions.length, before);
    });
  });

  // ── Transaction editing ──────────────────────────────────────────────────────

  group('Transaction editing', () {
    test('openDraftForEdit pre-fills the draft from the transaction', () async {
      final s = await makeState();
      final tx = s.transactions.first;
      s.openDraftForEdit(tx);
      expect(s.draft.editingId, tx.id);
      expect(s.draft.categoryId, tx.categoryId);
      expect(s.draft.label, tx.label);
      expect(s.draft.date, tx.createdAt);
      expect(double.parse(s.draft.amount), tx.amount);
    });

    test('saveTransaction updates an existing transaction in place', () async {
      final s = await makeState();
      final tx = s.transactions.first;
      final countBefore = s.transactions.length;
      s.openDraftForEdit(tx);
      s.draftKeyPress('del');
      while (s.draft.amount != '0') {
        s.draftKeyPress('del');
      }
      s.draftKeyPress('7');
      s.draftKeyPress('5');
      s.draftSetLabel('Edited label');
      s.saveTransaction();
      expect(s.transactions.length, countBefore); // no new tx added
      final updated = s.transactions.firstWhere((t) => t.id == tx.id);
      expect(updated.amount, 75.0);
      expect(updated.label, 'Edited label');
    });

    test('editing can change the date', () async {
      final s = await makeState();
      final tx = s.transactions.first;
      s.openDraftForEdit(tx);
      final newDate = DateTime(2026, 5, 1);
      s.draftSetDate(newDate);
      s.saveTransaction();
      final updated = s.transactions.firstWhere((t) => t.id == tx.id);
      expect(updated.createdAt.year, 2026);
      expect(updated.createdAt.month, 5);
      expect(updated.createdAt.day, 1);
      // time of day is preserved from the original transaction
      expect(updated.createdAt.hour, tx.createdAt.hour);
    });

    test('editing can change the category', () async {
      final s = await makeState();
      final tx = s.transactions.first;
      final otherCat =
          s.categories.firstWhere((c) => c.id != tx.categoryId).id;
      s.openDraftForEdit(tx);
      s.draftSetCategory(otherCat);
      s.saveTransaction();
      expect(
          s.transactions.firstWhere((t) => t.id == tx.id).categoryId, otherCat);
    });
  });

  // ── Smart categorization ─────────────────────────────────────────────────────

  group('Smart categorization', () {
    test('grocery keywords map to Groceries', () {
      expect(SmartCategorizer.suggest('Milk'), 'Groceries');
      expect(SmartCategorizer.suggest('cheese and bread'), 'Groceries');
      expect(SmartCategorizer.suggest('Veggies'), 'Groceries');
    });

    test('common merchants map to expected subcategories', () {
      expect(SmartCategorizer.suggest('Spotify'), 'Subscriptions');
      expect(SmartCategorizer.suggest('Netflix'), 'Subscriptions');
      expect(SmartCategorizer.suggest('Rent'), 'Housing');
      expect(SmartCategorizer.suggest('Gas'), 'Transport');
      expect(SmartCategorizer.suggest('Electricity'), 'Utilities');
      expect(SmartCategorizer.suggest('Vanguard'), 'Investments');
      expect(SmartCategorizer.suggest('Restaurant'), 'Dining');
    });

    test('unknown labels return empty string', () {
      expect(SmartCategorizer.suggest('xyzzy'), '');
      expect(SmartCategorizer.suggest(''), '');
    });

    test('keyword match respects word boundaries', () {
      expect(SmartCategorizer.suggest('Las Vegas trip'), isNot('Transport'));
    });

    test('user history overrides keyword matching', () {
      final history = [
        TransactionModel(
            amount: 10, categoryId: 'x', label: 'Milk', subcategory: 'Health'),
      ];
      expect(SmartCategorizer.suggest('milk', history), 'Health');
    });

    test('draftSetLabel auto-suggests a subcategory', () async {
      final s = await makeState();
      s.openDraft();
      s.draftSetLabel('cheese');
      expect(s.draft.subcategory, 'Groceries');
    });

    test('manual subcategory choice is not overwritten by typing', () async {
      final s = await makeState();
      s.openDraft();
      s.draftSetSubcategory('Travel');
      s.draftSetLabel('milk');
      expect(s.draft.subcategory, 'Travel');
    });

    test('tapping the selected subcategory reverts to auto', () async {
      final s = await makeState();
      s.openDraft();
      s.draftSetLabel('milk');
      s.draftSetSubcategory('Travel');
      expect(s.draft.subcategory, 'Travel');
      s.draftSetSubcategory('Travel'); // tap again to clear
      expect(s.draft.subcatManual, false);
      expect(s.draft.subcategory, 'Groceries'); // back to suggestion
    });

    test('saved transactions carry the subcategory', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('5');
      s.draftSetLabel('milk');
      s.saveTransaction();
      expect(s.transactions.last.subcategory, 'Groceries');
    });

    test('seeded demo transactions have subcategories', () async {
      final s = await makeState();
      final milk = s.transactions.firstWhere((t) => t.label == 'Milk');
      expect(milk.subcategory, 'Groceries');
      final spotify = s.transactions.firstWhere((t) => t.label == 'Spotify');
      expect(spotify.subcategory, 'Subscriptions');
    });

    test('subcategory survives JSON round-trip', () {
      final tx = TransactionModel(
          amount: 5, categoryId: 'c', label: 'Milk', subcategory: 'Groceries');
      final restored = TransactionModel.fromJson(tx.toJson());
      expect(restored.subcategory, 'Groceries');
    });

    test('fromJson tolerates legacy records without subcategory', () {
      final restored = TransactionModel.fromJson({
        'id': 'a',
        'amount': 5.0,
        'categoryId': 'c',
        'label': 'Milk',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(restored.subcategory, '');
    });
  });

  // ── Draft ────────────────────────────────────────────────────────────────────

  group('Draft — keypad', () {
    test('digits accumulate correctly', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      s.draftKeyPress('2');
      s.draftKeyPress('3');
      expect(s.draft.amount, '123');
    });

    test('leading zero is replaced on first digit', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('7');
      expect(s.draft.amount, '7');
    });

    test('decimal point is accepted once', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      s.draftKeyPress('.');
      s.draftKeyPress('5');
      expect(s.draft.amount, '1.5');
    });

    test('second decimal point is ignored', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      s.draftKeyPress('.');
      s.draftKeyPress('.');
      expect(s.draft.amount, '1.');
    });

    test('max two decimal places enforced', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      s.draftKeyPress('.');
      s.draftKeyPress('9');
      s.draftKeyPress('9');
      s.draftKeyPress('9'); // ignored
      expect(s.draft.amount, '1.99');
    });

    test('del removes last character', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      s.draftKeyPress('2');
      s.draftKeyPress('del');
      expect(s.draft.amount, '1');
    });

    test('del on single digit resets to 0', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('5');
      s.draftKeyPress('del');
      expect(s.draft.amount, '0');
    });

    test('del on 0 stays 0', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('del');
      expect(s.draft.amount, '0');
    });
  });

  group('Draft — validity', () {
    test('invalid when amount is 0', () async {
      final s = await makeState();
      s.openDraft();
      expect(s.draftIsValid, false);
    });

    test('valid when amount > 0 and category is set', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('1');
      expect(s.draftIsValid, true);
    });

    test('draftSetLabel stores label', () async {
      final s = await makeState();
      s.openDraft();
      s.draftSetLabel('Coffee');
      expect(s.draft.label, 'Coffee');
    });

    test('draftSetCategory updates categoryId', () async {
      final s = await makeState();
      s.openDraft();
      final catId = s.categories.last.id;
      s.draftSetCategory(catId);
      expect(s.draft.categoryId, catId);
    });

    test('openDraft with categoryId pre-selects category', () async {
      final s = await makeState();
      final catId = s.categories.last.id;
      s.openDraft(categoryId: catId);
      expect(s.draft.categoryId, catId);
    });
  });

  // ── Filtering ────────────────────────────────────────────────────────────────

  group('Filtering', () {
    test('month filter returns only current-month transactions', () async {
      final s = await makeState();
      final now = DateTime.now();
      final result = s.filtered('month');
      expect(
        result.every((t) =>
            t.createdAt.year == now.year && t.createdAt.month == now.month),
        true,
      );
    });

    test('week filter returns only last 7 days', () async {
      final s = await makeState();
      final cutoff = DateTime.now().subtract(const Duration(days: 6));
      final result = s.filtered('week');
      expect(
        result.every((t) => !t.createdAt
            .isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))),
        true,
      );
    });

    test('year filter returns only current year', () async {
      final s = await makeState();
      final result = s.filtered('year');
      expect(
        result.every((t) => t.createdAt.year == DateTime.now().year),
        true,
      );
    });

    test('all filter returns every transaction', () async {
      final s = await makeState();
      expect(s.filtered('all').length, s.transactions.length);
    });

    test('custom filter respects from/to bounds', () async {
      final s = await makeState();
      final from = DateTime.now().subtract(const Duration(days: 3));
      final to = DateTime.now();
      final result = s.filtered('custom', from: from, to: to);
      expect(
        result.every((t) => !t.createdAt
            .isBefore(DateTime(from.year, from.month, from.day))),
        true,
      );
    });

    test('custom filter without dates returns all', () async {
      final s = await makeState();
      expect(s.filtered('custom').length, s.transactions.length);
    });

    test('unknown period returns all transactions', () async {
      final s = await makeState();
      expect(s.filtered('bogus').length, s.transactions.length);
    });

    test('monthSpentForCat matches manual sum', () async {
      final s = await makeState();
      final catId = s.categories.first.id;
      final expected = s
          .filtered('month')
          .where((t) => t.categoryId == catId)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(s.monthSpentForCat(catId), expected);
    });
  });

  // ── Custom subcategories ─────────────────────────────────────────────────────

  group('Custom subcategories', () {
    test('addCustomSubcategory adds and selects it in the draft', () async {
      final s = await makeState();
      s.openDraft();
      final result = s.addCustomSubcategory('Pets');
      expect(result, 'Pets');
      expect(s.customSubcategories, contains('Pets'));
      expect(s.draft.subcategory, 'Pets');
      expect(s.draft.subcatManual, true);
    });

    test('duplicate names reuse the existing entry (case-insensitive)', () async {
      final s = await makeState();
      s.openDraft();
      s.addCustomSubcategory('Pets');
      final result = s.addCustomSubcategory('  pets ');
      expect(result, 'Pets');
      expect(s.customSubcategories.where((c) => c.toLowerCase() == 'pets').length, 1);
    });

    test('built-in names are not duplicated as custom', () async {
      final s = await makeState();
      s.openDraft();
      final result = s.addCustomSubcategory('groceries');
      expect(result, 'Groceries'); // canonical built-in casing
      expect(s.customSubcategories, isEmpty);
      expect(s.draft.subcategory, 'Groceries');
    });

    test('empty name is rejected', () async {
      final s = await makeState();
      s.openDraft();
      expect(s.addCustomSubcategory('   '), isNull);
      expect(s.customSubcategories, isEmpty);
    });

    test('allSubcategories includes built-in and custom', () async {
      final s = await makeState();
      s.openDraft();
      s.addCustomSubcategory('Kids');
      expect(s.allSubcategories, contains('Groceries'));
      expect(s.allSubcategories, contains('Kids'));
    });

    test('custom subcategories persist across launches', () async {
      SharedPreferences.setMockInitialValues({});
      final s1 = AppState();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      s1.openDraft();
      s1.addCustomSubcategory('Hobbies');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final s2 = AppState();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(s2.customSubcategories, contains('Hobbies'));
    });

    test('transactions saved with a custom subcategory keep it', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('5');
      s.addCustomSubcategory('Pets');
      s.draftSetLabel('dog food');
      s.saveTransaction();
      expect(s.transactions.last.subcategory, 'Pets');
    });

    test('history learning suggests custom subcategory for same label', () async {
      final s = await makeState();
      s.openDraft();
      s.draftKeyPress('5');
      s.addCustomSubcategory('Pets');
      s.draftSetLabel('dog food');
      s.saveTransaction();

      s.openDraft();
      s.draftSetLabel('dog food');
      expect(s.draft.subcategory, 'Pets');
    });
  });

  // ── Budget status ────────────────────────────────────────────────────────────

  group('Budget status', () {
    test('on track below 80%', () {
      expect(BudgetHealth.statusFor(spent: 79, limit: 100),
          BudgetStatus.onTrack);
      expect(BudgetHealth.statusFor(spent: 0, limit: 100),
          BudgetStatus.onTrack);
    });

    test('near limit at 80–99%', () {
      expect(BudgetHealth.statusFor(spent: 80, limit: 100),
          BudgetStatus.nearLimit);
      expect(BudgetHealth.statusFor(spent: 99.9, limit: 100),
          BudgetStatus.nearLimit);
    });

    test('over at 100%+', () {
      expect(BudgetHealth.statusFor(spent: 100, limit: 100),
          BudgetStatus.over);
      expect(BudgetHealth.statusFor(spent: 150, limit: 100),
          BudgetStatus.over);
    });

    test('savings reports achieved instead of over', () {
      expect(
          BudgetHealth.statusFor(spent: 100, limit: 100, isSavings: true),
          BudgetStatus.achieved);
      expect(
          BudgetHealth.statusFor(spent: 120, limit: 100, isSavings: true),
          BudgetStatus.achieved);
    });

    test('savings never warns below target', () {
      expect(
          BudgetHealth.statusFor(spent: 90, limit: 100, isSavings: true),
          BudgetStatus.onTrack);
    });

    test('zero limit is always on track', () {
      expect(BudgetHealth.statusFor(spent: 50, limit: 0),
          BudgetStatus.onTrack);
    });

    test('isSavings detects savings-like category names', () {
      CategoryModel cat(String name) =>
          CategoryModel(name: name, pct: 20, color: const Color(0xFF000000));
      expect(BudgetHealth.isSavings(cat('Savings')), true);
      expect(BudgetHealth.isSavings(cat('savings fund')), true);
      expect(BudgetHealth.isSavings(cat('Wants')), false);
      expect(BudgetHealth.isSavings(cat('Needs')), false);
    });
  });

  // ── CSV export ───────────────────────────────────────────────────────────────

  group('CSV export', () {
    test('header row and one line per transaction', () async {
      final s = await makeState();
      final txs = s.filtered('month');
      final csv = CsvExporter.build(txs, s.categories, s.user.currency);
      final lines = csv.trim().split('\r\n');
      expect(lines.first,
          'Date,Time,Label,Category,Subcategory,Amount,Currency');
      expect(lines.length, txs.length + 1);
    });

    test('row contains date, label, category, subcategory, amount', () async {
      final s = await makeState();
      final milk = s.transactions.firstWhere((t) => t.label == 'Milk');
      final csv = CsvExporter.build([milk], s.categories, 'USD');
      final row = csv.trim().split('\r\n')[1];
      final cells = row.split(',');
      expect(cells[2], 'Milk');
      expect(cells[3], 'Needs');
      expect(cells[4], 'Groceries');
      expect(cells[5], '4.20');
      expect(cells[6], 'USD');
    });

    test('fields with commas and quotes are escaped', () {
      final tx = TransactionModel(
        amount: 9.5,
        categoryId: 'c',
        label: 'Bread, eggs and "stuff"',
        subcategory: 'Groceries',
        createdAt: DateTime(2026, 6, 1, 10, 30),
      );
      final cat = CategoryModel(id: 'c', name: 'Needs', pct: 50,
          color: const Color(0xFF000000));
      final csv = CsvExporter.build([tx], [cat], 'USD');
      expect(csv, contains('"Bread, eggs and ""stuff"""'));
    });

    test('custom date range export only includes range', () async {
      final s = await makeState();
      final from = DateTime.now().subtract(const Duration(days: 3));
      final to = DateTime.now();
      final txs = s.filtered('custom', from: from, to: to);
      final csv = CsvExporter.build(txs, s.categories, 'USD');
      expect(csv.trim().split('\r\n').length, txs.length + 1);
    });
  });

  // ── Navigation ───────────────────────────────────────────────────────────────

  group('Navigation', () {
    test('setTab updates activeTab', () async {
      final s = await makeState();
      s.setTab(1);
      expect(s.activeTab, 1);
      s.setTab(2);
      expect(s.activeTab, 2);
    });
  });

  // ── Period setters ───────────────────────────────────────────────────────────

  group('Period setters', () {
    test('setActivityPeriod clears custom range', () async {
      final s = await makeState();
      s.setActivityRange(DateTime.now(), DateTime.now());
      s.setActivityPeriod('week');
      expect(s.activityPeriod, 'week');
      expect(s.activityFrom, isNull);
      expect(s.activityTo, isNull);
    });

    test('setActivityPeriod custom preserves range', () async {
      final s = await makeState();
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 1, 31);
      s.setActivityRange(from, to);
      s.setActivityPeriod('custom');
      expect(s.activityFrom, from);
      expect(s.activityTo, to);
    });

    test('setInsightsPeriod clears range for non-custom', () async {
      final s = await makeState();
      s.setInsightsRange(DateTime.now(), DateTime.now());
      s.setInsightsPeriod('year');
      expect(s.insightsPeriod, 'year');
      expect(s.insightsFrom, isNull);
    });

    test('setInsightsCat updates selected category id', () async {
      final s = await makeState();
      final id = s.categories.last.id;
      s.setInsightsCat(id);
      expect(s.insightsSelectedCatId, id);
    });
  });

  // ── Persistence — JSON serialization ─────────────────────────────────────────

  group('Persistence — JSON round-trip', () {
    test('CategoryModel serializes and deserializes correctly', () async {
      final s = await makeState();
      final cat = s.categories.first;
      final restored = CategoryModel.fromJson(cat.toJson());
      expect(restored.id, cat.id);
      expect(restored.name, cat.name);
      expect(restored.pct, cat.pct);
      expect(restored.color.toARGB32(), cat.color.toARGB32());
    });

    test('TransactionModel serializes and deserializes correctly', () async {
      final s = await makeState();
      final tx = s.transactions.first;
      final restored = TransactionModel.fromJson(tx.toJson());
      expect(restored.id, tx.id);
      expect(restored.amount, tx.amount);
      expect(restored.categoryId, tx.categoryId);
      expect(restored.label, tx.label);
      expect(
        restored.createdAt.toIso8601String(),
        tx.createdAt.toIso8601String(),
      );
    });

    test('All demo categories survive JSON round-trip', () async {
      final s = await makeState();
      for (final cat in s.categories) {
        final restored = CategoryModel.fromJson(cat.toJson());
        expect(restored.id, cat.id);
        expect(restored.pct, cat.pct);
      }
    });

    test('All demo transactions survive JSON round-trip', () async {
      final s = await makeState();
      for (final tx in s.transactions) {
        final restored = TransactionModel.fromJson(tx.toJson());
        expect(restored.id, tx.id);
        expect(restored.amount, tx.amount);
      }
    });

    test('state is restored from SharedPreferences on second launch', () async {
      SharedPreferences.setMockInitialValues({});
      final s1 = AppState();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Record count and add one transaction
      final countBefore = s1.transactions.length;
      s1.openDraft();
      s1.draftKeyPress('9');
      s1.draftKeyPress('9');
      s1.saveTransaction();

      // Allow _save() to flush
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Second launch — no setMockInitialValues so prefs carry over
      final s2 = AppState();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(s2.transactions.length, countBefore + 1);
      expect(s2.transactions.last.amount, 99.0);
    });
  });
}
