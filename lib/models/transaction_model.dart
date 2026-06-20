import 'package:uuid/uuid.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String categoryId;
  final String label;
  final String subcategory;
  final DateTime createdAt;

  TransactionModel({
    String? id,
    required this.amount,
    required this.categoryId,
    required this.label,
    this.subcategory = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TransactionModel copyWith({
    double? amount,
    String? categoryId,
    String? label,
    String? subcategory,
    DateTime? createdAt,
  }) =>
      TransactionModel(
        id: id,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        label: label ?? this.label,
        subcategory: subcategory ?? this.subcategory,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'label': label,
        'subcategory': subcategory,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        label: json['label'] as String,
        subcategory: (json['subcategory'] as String?) ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
