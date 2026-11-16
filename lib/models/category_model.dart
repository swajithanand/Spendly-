import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CategoryModel {
  final String id;
  String name;
  int pct;
  Color color;

  /// Savings-type categories are goals, not caps: reaching the allocation is
  /// a success. When not given, it is inferred once from the name.
  bool isSavings;

  CategoryModel({
    String? id,
    required this.name,
    required this.pct,
    required this.color,
    bool? isSavings,
  })  : id = (id != null && id.isNotEmpty && id != '_') ? id : const Uuid().v4(),
        isSavings = isSavings ?? looksLikeSavings(name);

  /// Name heuristic, used only as the default for new or legacy categories.
  static bool looksLikeSavings(String name) {
    final n = name.toLowerCase();
    return n.contains('sav') || n.contains('invest');
  }

  /// Copy with a fresh id, or with [id] when given.
  CategoryModel clone({String? id}) => CategoryModel(
      id: id, name: name, pct: pct, color: color, isSavings: isSavings);

  CategoryModel copyWith(
          {String? name, int? pct, Color? color, bool? isSavings}) =>
      CategoryModel(
        id: id,
        name: name ?? this.name,
        pct: pct ?? this.pct,
        color: color ?? this.color,
        isSavings: isSavings ?? this.isSavings,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pct': pct,
        'color': color.toARGB32(),
        'isSavings': isSavings,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        pct: json['pct'] as int,
        color: Color(json['color'] as int),
        isSavings: json['isSavings'] as bool?,
      );
}
