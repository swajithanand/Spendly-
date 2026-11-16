import 'package:uuid/uuid.dart';

/// What kind of thing an inventory item is. Stored by [name], so do not
/// rename values without a migration.
enum InventoryKind { food, electronics, household, medicine, other }

/// What the item's date means.
enum DueType { none, expiry, service, reminder }

extension InventoryKindInfo on InventoryKind {
  String get label => switch (this) {
        InventoryKind.food => 'Food & groceries',
        InventoryKind.electronics => 'Electronics',
        InventoryKind.household => 'Household',
        InventoryKind.medicine => 'Medicine',
        InventoryKind.other => 'Other',
      };

  String get shortLabel => switch (this) {
        InventoryKind.food => 'Food',
        InventoryKind.electronics => 'Electronics',
        InventoryKind.household => 'Household',
        InventoryKind.medicine => 'Medicine',
        InventoryKind.other => 'Other',
      };

  String get emoji => switch (this) {
        InventoryKind.food => '🛒',
        InventoryKind.electronics => '🔌',
        InventoryKind.household => '🏠',
        InventoryKind.medicine => '💊',
        InventoryKind.other => '📦',
      };

  /// The date type that usually matters for this kind of item.
  DueType get defaultDueType => switch (this) {
        InventoryKind.food || InventoryKind.medicine => DueType.expiry,
        InventoryKind.electronics => DueType.service,
        _ => DueType.reminder,
      };
}

extension DueTypeInfo on DueType {
  String get label => switch (this) {
        DueType.none => 'No date',
        DueType.expiry => 'Expires',
        DueType.service => 'Service due',
        DueType.reminder => 'Reminder',
      };
}

/// How urgent an item's date is, relative to today.
enum DueStatus { none, ok, soon, overdue }

/// One thing the user keeps at home.
class InventoryItem {
  final String id;
  final String name;
  final InventoryKind kind;
  final double quantity;
  final String unit;
  final DueType dueType;
  final DateTime? dueDate;
  final String note;

  /// The spending this item was added from, if any.
  final String? txId;
  final DateTime createdAt;

  InventoryItem({
    String? id,
    required this.name,
    this.kind = InventoryKind.other,
    this.quantity = 1,
    this.unit = 'pcs',
    this.dueType = DueType.none,
    this.dueDate,
    this.note = '',
    this.txId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Days from [now] until the due date (negative when past). Null when the
  /// item has no date. Compares calendar days, not hours.
  int? daysLeft([DateTime? now]) {
    final due = dueDate;
    if (due == null || dueType == DueType.none) return null;
    final n = now ?? DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(n.year, n.month, n.day))
        .inDays;
  }

  /// [soonDays] is how far ahead counts as "soon".
  DueStatus status({DateTime? now, int soonDays = 7}) {
    final d = daysLeft(now);
    if (d == null) return DueStatus.none;
    if (d < 0) return DueStatus.overdue;
    if (d <= soonDays) return DueStatus.soon;
    return DueStatus.ok;
  }

  bool get isOut => quantity <= 0;

  InventoryItem copyWith({
    String? name,
    InventoryKind? kind,
    double? quantity,
    String? unit,
    DueType? dueType,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
  }) =>
      InventoryItem(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        dueType: dueType ?? this.dueType,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        note: note ?? this.note,
        txId: txId,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'quantity': quantity,
        'unit': unit,
        'dueType': dueType.name,
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
        'txId': txId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: InventoryKind.values.asNameMap()[json['kind']] ??
            InventoryKind.other,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: (json['unit'] as String?) ?? 'pcs',
        dueType: DueType.values.asNameMap()[json['dueType']] ?? DueType.none,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        note: (json['note'] as String?) ?? '',
        txId: json['txId'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );
}

/// A purchase the user chose to add to the inventory "later".
class PendingInventory {
  final String txId;
  final String name;
  final InventoryKind kind;
  final DateTime purchasedAt;

  const PendingInventory({
    required this.txId,
    required this.name,
    required this.kind,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() => {
        'txId': txId,
        'name': name,
        'kind': kind.name,
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory PendingInventory.fromJson(Map<String, dynamic> json) =>
      PendingInventory(
        txId: json['txId'] as String,
        name: json['name'] as String,
        kind: InventoryKind.values.asNameMap()[json['kind']] ??
            InventoryKind.other,
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      );
}
