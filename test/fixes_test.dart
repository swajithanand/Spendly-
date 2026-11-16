import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/budget_status.dart';
import 'package:spendly/core/categorizer.dart';
import 'package:spendly/core/money.dart';
import 'package:spendly/models/category_model.dart';
import 'package:spendly/models/transaction_model.dart';
import 'package:spendly/state/app_state.dart';

Future<void> settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Fresh AppState on empty storage, fully loaded.
Future<AppState> makeState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.ready;
  return state;
}

/// A second "launch" that reads whatever the previous state saved.
Future<AppState> relaunch() async {
  await settle();
  final state = AppState();
  await state.ready;
  return state;
}

void main() {
  group('Presets keep transactions attached', () {
    test('same-named categories keep their id', () async {
      final s = await makeState();
      final savingsId = s.categories.firstWhere((c) => c.name == 'Savings').id;
      s.applyPreset(3); // Saver: Essentials / Lifestyle / Savings
      expect(s.categories.firstWhere((c) => c.name == 'Savings').id, savingsId);
      expect(s.categories.firstWhere((c) => c.name == 'Savings').pct, 40);
    });

    test('orphansIfPresetApplied counts only transactions that lose a home',
        () async {
      final s = await makeState();
      final savingsId = s.categories.firstWhere((c) => c.name == 'Savings').id;
      final notSavings =
          s.transactions.where((t) => t.categoryId != savingsId).length;
      expect(notSavings, greaterThan(0));
      expect(s.orphansIfPresetApplied(3), notSavings);
      expect(s.orphansIfPresetApplied(0), 0); // re-applying the same preset
    });

    test('re-applying the current preset orphans nothing', () async {
      final s = await makeState();
      s.applyPreset(0);
      expect(s.txsForCat(s.transactions, AppState.uncategorizedId), isEmpty);
    });
  });

  group('Uncategorized', () {
    test('transactions of a deleted category are reported, not dropped',
        () async {
      final s = await makeState();
      final wants = s.categories.firstWhere((c) => c.name == 'Wants');
      final wantsCount =
          s.transactions.where((t) => t.categoryId == wants.id).length;
      s.removeCategory(wants.id);

      final orphans = s.txsForCat(s.transactions, AppState.uncategorizedId);
      expect(orphans.length, wantsCount);

      // Every transaction is in exactly one bucket.
      final bucketed = s.categories
              .map((c) => s.txsForCat(s.transactions, c.id).length)
              .fold(0, (a, b) => a + b) +
          orphans.length;
      expect(bucketed, s.transactions.length);
    });

    test('editing an orphan leaves the category unselected', () async {
      final s = await makeState();
      final wants = s.categories.firstWhere((c) => c.name == 'Wants');
      final tx = s.transactions.firstWhere((t) => t.categoryId == wants.id);
      s.removeCategory(wants.id);
      s.openDraftForEdit(tx);
      expect(s.draft.categoryId, isNull);
      expect(s.draftIsValid, false);
      s.draftSetCategory(s.categories.first.id);
      s.saveTransaction();
      expect(s.transactions.firstWhere((t) => t.id == tx.id).categoryId,
          s.categories.first.id);
    });
  });

  group('Loading damaged data', () {
    test('corrupt transactions do not crash and are backed up', () async {
      final good = await makeState();
      good.setIncome(5000);
      await settle();
      final prefs = await SharedPreferences.getInstance();
      final cats = prefs.getString('categories')!;

      SharedPreferences.setMockInitialValues({
        'income': 5000.0,
        'categories': cats,
        'transactions': '[{"id": "broken',
      });
      final s = AppState();
      await s.ready;

      expect(s.loaded, true);
      expect(s.loadError, isNotNull);
      expect(s.income, 5000.0);
      expect(s.categories.map((c) => c.name), ['Needs', 'Wants', 'Savings']);
      expect(s.transactions, isEmpty);
      expect(s.hasDemoData, false); // real users never get demo data re-seeded

      // The unreadable text survives later saves.
      s.setIncome(5100);
      await settle();
      final after = await SharedPreferences.getInstance();
      expect(after.getString('corruptBackup_transactions'),
          '[{"id": "broken');
    });

    test('a change made before loading finishes is not lost', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      s.updateProfile(name: 'Early Bird'); // before load completes
      await s.ready;
      final s2 = await relaunch();
      expect(s2.transactions, isNotEmpty); // seeded data was saved too
      expect(s2.categories, isNotEmpty);
    });
  });

  group('Delete with undo', () {
    test('undoDelete restores the transaction in place', () async {
      final s = await makeState();
      final before = s.transactions.map((t) => t.id).toList();
      final victim = s.transactions[3];
      s.deleteTransaction(victim.id);
      expect(s.transactions.any((t) => t.id == victim.id), false);
      expect(s.undoDelete(), true);
      expect(s.transactions.map((t) => t.id).toList(), before);
      expect(s.undoDelete(), false); // nothing left to undo
    });

    test('undo survives a relaunch', () async {
      final s = await makeState();
      final victim = s.transactions.first;
      s.deleteTransaction(victim.id);
      s.undoDelete();
      final s2 = await relaunch();
      expect(s2.transactions.any((t) => t.id == victim.id), true);
    });
  });

  group('Budget cycle', () {
    test('1st: cycle is the calendar month', () async {
      final s = await makeState();
      expect(s.cycleStartDate(DateTime(2026, 11, 20)), DateTime(2026, 11, 1));
      expect(s.cycleEndDate(DateTime(2026, 11, 20)), DateTime(2026, 12, 1));
      expect(s.cycleLabel(DateTime(2026, 11, 20)), 'November 2026');
    });

    test('15th: cycle runs from the 15th to the 14th', () async {
      final s = await makeState();
      s.setCycleStart('15th');
      expect(s.cycleStartDate(DateTime(2026, 11, 20)), DateTime(2026, 11, 15));
      expect(s.cycleStartDate(DateTime(2026, 11, 10)), DateTime(2026, 10, 15));
      expect(s.cycleStartDate(DateTime(2027, 1, 3)), DateTime(2026, 12, 15));
      expect(s.cycleLabel(DateTime(2026, 11, 20)), 'Nov 15 – Dec 14');
    });

    test('"month" filter follows the cycle start', () async {
      final s = await makeState();
      s.transactions.clear();
      final now = DateTime.now();
      final cat = s.categories.first.id;
      TransactionModel tx(DateTime d) =>
          TransactionModel(amount: 10, categoryId: cat, label: 'x', createdAt: d);

      s.setCycleStart('15th');
      final start = s.cycleStartDate(now);
      s.transactions.addAll([
        tx(start), // first moment of the cycle: in
        tx(start.subtract(const Duration(days: 1))), // day before: out
      ]);
      expect(s.filtered('month').length, 1);
      expect(s.monthSpentForCat(cat), 10);
    });
  });

  group('Sign-in is remembered', () {
    test('signed-in and finished setup survive a relaunch', () async {
      final s = await makeState();
      s.signIn(email: 'a@b.com');
      expect(s.isOnboarding, true);
      s.completeSetup();
      final s2 = await relaunch();
      expect(s2.signedIn, true);
      expect(s2.isOnboarding, false);
    });

    test('signing back in after setup skips onboarding', () async {
      final s = await makeState();
      s.signIn(email: 'a@b.com');
      s.completeSetup();
      s.signOut();
      final s2 = await relaunch();
      expect(s2.signedIn, false);
      s2.signIn(email: 'a@b.com');
      expect(s2.isOnboarding, false);
    });
  });

  group('Savings flag', () {
    CategoryModel cat(String name, {bool? isSavings}) => CategoryModel(
        name: name, pct: 10, color: Colors.black, isSavings: isSavings);

    test('investment-like names default to savings', () {
      expect(BudgetHealth.isSavings(cat('Investments')), true);
      expect(BudgetHealth.isSavings(cat('Rent')), false);
    });

    test('explicit flag wins over the name', () {
      expect(BudgetHealth.isSavings(cat('Savings', isSavings: false)), false);
      expect(BudgetHealth.isSavings(cat('House fund', isSavings: true)), true);
    });

    test('renaming does not flip the flag; toggling persists', () async {
      final s = await makeState();
      final savings = s.categories.firstWhere((c) => c.name == 'Savings');
      s.updateCategoryName(savings.id, 'Future me');
      expect(savings.isSavings, true);

      final needs = s.categories.firstWhere((c) => c.name == 'Needs');
      s.updateCategorySavings(needs.id, true);
      final s2 = await relaunch();
      expect(s2.categories.firstWhere((c) => c.name == 'Needs').isSavings, true);
      expect(
          s2.categories.firstWhere((c) => c.name == 'Future me').isSavings, true);
    });

    test('legacy saved categories without the flag infer it from the name', () {
      final c = CategoryModel.fromJson(
          {'id': 'x', 'name': 'Savings', 'pct': 20, 'color': 0xFF000000});
      expect(c.isSavings, true);
    });
  });

  group('Categorizer whole-word matching', () {
    test('no longer matches keyword prefixes of other words', () {
      expect(SmartCategorizer.suggest('Barber'), isNot('Dining'));
      expect(SmartCategorizer.suggest('Business cards'), isNot('Transport'));
      expect(SmartCategorizer.suggest('Shower curtain'), isNot('Entertainment'));
      expect(SmartCategorizer.suggest('Classic vinyl'), isNot('Education'));
    });

    test('still matches plurals and common forms', () {
      expect(SmartCategorizer.suggest('Eggs'), 'Groceries');
      expect(SmartCategorizer.suggest('Groceries'), 'Groceries');
      expect(SmartCategorizer.suggest('Bus'), 'Transport');
      expect(SmartCategorizer.suggest('Buses'), 'Transport');
      expect(SmartCategorizer.suggest("McDonald's"), 'Dining');
      expect(SmartCategorizer.suggest('Movie tickets'), 'Entertainment');
      expect(SmartCategorizer.suggest('Bar tab'), 'Dining');
    });
  });

  group('Money formatting', () {
    test('keeps trailing zeros on fractional amounts', () {
      const f = MoneyFormat('USD');
      expect(f.format(4.2), '4.20');
      expect(f.format(11.99), '11.99');
      expect(f.format(1450), '1,450');
      expect(f.format(1450.5), '1,450.50');
      expect(f.format(0), '0');
    });

    test('uses lakh grouping for rupee-style currencies', () {
      expect(const MoneyFormat('INR').format(150000), '1,50,000');
      expect(const MoneyFormat('INR').format(1234567.5), '12,34,567.50');
      expect(const MoneyFormat('USD').format(150000), '150,000');
    });
  });

  group('Sample data', () {
    test('first launch is flagged as sample data and can be cleared', () async {
      final s = await makeState();
      expect(s.hasDemoData, true);

      s.openDraft(categoryId: s.categories.first.id);
      s.draftKeyPress('7');
      s.draftSetLabel('Mine');
      s.saveTransaction();

      s.clearDemoData();
      expect(s.hasDemoData, false);
      expect(s.transactions.map((t) => t.label), ['Mine']);

      final s2 = await relaunch();
      expect(s2.hasDemoData, false);
      expect(s2.transactions.map((t) => t.label), ['Mine']);
    });
  });
}
