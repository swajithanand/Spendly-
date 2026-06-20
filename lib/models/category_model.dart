import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CategoryModel {
  final String id;
  String name;
  int pct;
  Color color;

  CategoryModel({
    String? id,
    required this.name,
    required this.pct,
    required this.color,
  }) : id = (id != null && id.isNotEmpty && id != '_') ? id : const Uuid().v4();

  CategoryModel clone() => CategoryModel(name: name, pct: pct, color: color);

  CategoryModel copyWith({String? name, int? pct, Color? color}) => CategoryModel(
        id: id,
        name: name ?? this.name,
        pct: pct ?? this.pct,
        color: color ?? this.color,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pct': pct,
        'color': color.toARGB32(),
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        pct: json['pct'] as int,
        color: Color(json['color'] as int),
      );
}
