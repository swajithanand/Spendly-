import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/inventory_rules.dart';
import 'package:spendly/models/inventory_item.dart';
import 'package:spendly/models/transaction_model.dart';
import 'package:spendly/state/app_state.dart';
import 'package:spendly/widgets/inventory_item_sheet.dart';

Future<void> settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<AppState> makeState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.ready;
  return state;
}

Future<AppState> relaunch() async {
  await settle();
  final state = AppState();
  await state.ready;
  return state;
}

TransactionModel tx(String label, String subcategory) => TransactionModel(
    amount: 10, categoryId: 'c', label: label, subcategory: subcategory);

void main() {
  final today = DateTime(2026, 11, 15, 14, 30);

  group('InventoryItem dates', () {
    InventoryItem item(DateTime? due, [DueType type = DueType.expiry]) =>
        InventoryItem(name: 'Milk', dueType: type, dueDate: due);

    test('no date means no status', () {
      expect(item(null).status(now: today), DueStatus.none);
      expect(item(null).daysLeft(today), isNull);
      // A date with type "none" is ignored too.
      expect(item(DateTime(2026, 11, 16), DueType.none).status(now: today),
          DueStatus.none);
    });

    test('counts calendar days, ignoring the time of day', () {
      expect(item(DateTime(2026, 11, 15, 0, 1)).daysLeft(today), 0);
      expect(item(DateTime(2026, 11, 16, 23, 59)).daysLeft(today), 1);
      expect(item(DateTime(2026, 11, 14, 23, 59)).daysLeft(today), -1);
    });

    test('status boundaries', () {
      expect(item(DateTime(2026, 11, 14)).status(now: today), DueStatus.overdue);
      expect(item(DateTime(2026, 11, 15)).status(now: today), DueStatus.soon);
      expect(item(DateTime(2026, 11, 22)).status(now: today), DueStatus.soon);
      expect(item(DateTime(2026, 11, 23)).status(now: today), DueStatus.ok);
    });

    test('descriptions read naturally', () {
      expect(describeDue(item(DateTime(2026, 11, 15)), today), 'Expires today');
      expect(describeDue(item(DateTime(2026, 11, 16)), today),
          'Expires tomorrow');
      expect(describeDue(item(DateTime(2026, 11, 18)), today),
          'Expires in 3 days');
      expect(describeDue(item(DateTime(2026, 11, 14)), today),
          'Expired 1 day ago');
      expect(
          describeDue(item(DateTime(2026, 11, 10), DueType.service), today),
          'Service overdue by 5 days');
      expect(describeDue(item(DateTime(2027, 3, 1), DueType.service), today),
          'Service due Mar 1, 2027');
      expect(describeDue(item(null), today), '');
    });

    test('JSON round-trip keeps every field', () {
      final a = InventoryItem(
        name: 'Washing machine',
        kind: InventoryKind.electronics,
        quantity: 1,
        unit: 'pcs',
        dueType: DueType.service,
        dueDate: DateTime(2027, 2, 1),
        note: 'Warranty in drawer',
        txId: 'tx1',
      );
      final b = InventoryItem.fromJson(a.toJson());
      expect(b.id, a.id);
      expect(b.name, a.name);
      expect(b.kind, a.kind);
      expect(b.quantity, a.quantity);
      expect(b.dueType, a.dueType);
      expect(b.dueDate, a.dueDate);
      expect(b.note, a.note);
      expect(b.txId, a.txId);
    });

    test('unknown kind or date type from a newer version does not crash', () {
      final i = InventoryItem.fromJson({
        'id': 'x',
        'name': 'Thing',
        'kind': 'spaceship',
        'dueType': 'someday',
      });
      expect(i.kind, InventoryKind.other);
      expect(i.dueType, DueType.none);
      expect(i.quantity, 1);
    });

    test('copyWith can clear the date', () {
      final i = item(DateTime(2026, 12, 1));
      expect(i.copyWith(clearDueDate: true).dueDate, isNull);
      expect(i.copyWith(quantity: 3).dueDate, DateTime(2026, 12, 1));
    });
  });

  group('Which purchases are offered for the inventory', () {
    test('groceries become food', () {
      expect(InventoryRules.kindFor(tx('Milk', 'Groceries')), InventoryKind.food);
    });

    test('electronics are recognised by name', () {
      expect(InventoryRules.kindFor(tx('New laptop', 'Shopping')),
          InventoryKind.electronics);
      expect(InventoryRules.kindFor(tx('Washing machine', '')),
          InventoryKind.electronics);
    });

    test('other shopping becomes household', () {
      expect(InventoryRules.kindFor(tx('Ikea shelves', 'Shopping')),
          InventoryKind.household);
    });

    test('medicine yes, doctor visit no', () {
      expect(InventoryRules.kindFor(tx('Vitamin tablets', 'Health')),
          InventoryKind.medicine);
      expect(InventoryRules.kindFor(tx('Dentist', 'Health')), isNull);
    });

    test('services and bills are not offered', () {
      expect(InventoryRules.kindFor(tx('Rent', 'Housing')), isNull);
      expect(InventoryRules.kindFor(tx('Restaurant', 'Dining')), isNull);
      expect(InventoryRules.kindFor(tx('Netflix', 'Subscriptions')), isNull);
      expect(InventoryRules.kindFor(tx('Electricity', 'Utilities')), isNull);
    });

    test('name falls back to the subcategory', () {
      expect(InventoryRules.nameFor(tx('  ', 'Groceries')), 'Groceries');
      expect(InventoryRules.nameFor(tx('Eggs', 'Groceries')), 'Eggs');
    });
  });

  group('Inventory in AppState', () {
    test('starts empty; add, update, quantity and delete with undo', () async {
      final s = await makeState();
      expect(s.inventory, isEmpty);

      final milk = InventoryItem(name: 'Milk', quantity: 2);
      s.addInventoryItem(milk);
      s.adjustInventoryQuantity(milk.id, -1);
      expect(s.inventory.single.quantity, 1);
      s.adjustInventoryQuantity(milk.id, -5); // never below zero
      expect(s.inventory.single.quantity, 0);
      expect(s.inventory.single.isOut, true);

      s.updateInventoryItem(s.inventory.single.copyWith(name: 'Oat milk'));
      expect(s.inventory.single.name, 'Oat milk');

      s.deleteInventoryItem(milk.id);
      expect(s.inventory, isEmpty);
      expect(s.undoDeleteInventoryItem(), true);
      expect(s.inventory.single.name, 'Oat milk');
      expect(s.undoDeleteInventoryItem(), false);
    });

    test('items and reminders survive a relaunch', () async {
      final s = await makeState();
      s.addInventoryItem(InventoryItem(
        name: 'Fridge',
        kind: InventoryKind.electronics,
        dueType: DueType.service,
        dueDate: DateTime(2027, 1, 10),
      ));
      s.deferInventory(tx('Rice', 'Groceries'));
      final s2 = await relaunch();
      expect(s2.inventory.single.name, 'Fridge');
      expect(s2.inventory.single.dueDate, DateTime(2027, 1, 10));
      expect(s2.pendingInventory.single.name, 'Rice');
      expect(s2.pendingInventory.single.kind, InventoryKind.food);
    });

    test('saving a new spending returns it; an edit returns null', () async {
      final s = await makeState();
      s.openDraft(categoryId: s.categories.first.id);
      s.draftKeyPress('5');
      s.draftSetLabel('Eggs');
      final created = s.saveTransaction();
      expect(created, isNotNull);
      expect(created!.subcategory, 'Groceries');
      expect(InventoryRules.kindFor(created), InventoryKind.food);

      s.openDraftForEdit(created);
      expect(s.saveTransaction(), isNull);
    });

    test('"remind me later" queues once and adding the item clears it',
        () async {
      final s = await makeState();
      final t = tx('Eggs', 'Groceries');
      s.deferInventory(t);
      s.deferInventory(t); // no duplicates
      expect(s.pendingInventory.length, 1);
      expect(s.inventoryBadgeCount, 1);

      s.addInventoryItem(InventoryItem(name: 'Eggs', txId: t.id));
      expect(s.pendingInventory, isEmpty);
      expect(s.inventory.single.txId, t.id);
    });

    test('a reminder can be dismissed', () async {
      final s = await makeState();
      final t = tx('Eggs', 'Groceries');
      s.deferInventory(t);
      s.dismissPendingInventory(t.id);
      expect(s.pendingInventory, isEmpty);
    });

    test('deleting the spending drops its reminder; undo brings it back',
        () async {
      final s = await makeState();
      s.openDraft(categoryId: s.categories.first.id);
      s.draftKeyPress('5');
      s.draftSetLabel('Eggs');
      final t = s.saveTransaction()!;
      s.deferInventory(t);

      s.deleteTransaction(t.id);
      expect(s.pendingInventory, isEmpty);
      s.undoDelete();
      expect(s.pendingInventory.single.txId, t.id);
    });

    test('attention list is overdue and due-soon items, most urgent first',
        () async {
      final s = await makeState();
      InventoryItem due(String name, int days) => InventoryItem(
            name: name,
            dueType: DueType.expiry,
            dueDate: today.add(Duration(days: days)),
          );
      s.addInventoryItem(due('Later', 30));
      s.addInventoryItem(due('Soon', 3));
      s.addInventoryItem(due('Expired', -2));
      s.addInventoryItem(InventoryItem(name: 'No date'));
      expect(s.inventoryAttention(today).map((i) => i.name),
          ['Expired', 'Soon']);
    });
  });

  group('Quantity formatting', () {
    test('drops pointless decimals', () {
      expect(formatQuantity(2), '2');
      expect(formatQuantity(1.5), '1.5');
      expect(formatQuantity(0.25), '0.25');
      expect(formatQuantity(0), '0');
    });
  });
}
