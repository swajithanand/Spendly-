import 'package:flutter/material.dart';
import '../models/category_model.dart';
import 'colors.dart';

class PresetBudget {
  final String name;
  final List<CategoryModel> categories;
  const PresetBudget({required this.name, required this.categories});
}

class AppConstants {
  static final List<PresetBudget> presets = [
    PresetBudget(
      name: '50 / 30 / 20',
      categories: [
        CategoryModel(id: '_', name: 'Needs', pct: 50, color: AppColors.indigo),
        CategoryModel(id: '_', name: 'Wants', pct: 30, color: AppColors.amber),
        CategoryModel(id: '_', name: 'Savings', pct: 20, color: AppColors.emerald),
      ],
    ),
    PresetBudget(
      name: '70 / 20 / 10',
      categories: [
        CategoryModel(id: '_', name: 'Living', pct: 70, color: AppColors.slate),
        CategoryModel(id: '_', name: 'Savings', pct: 20, color: AppColors.emerald),
        CategoryModel(id: '_', name: 'Fun', pct: 10, color: AppColors.pink),
      ],
    ),
    PresetBudget(
      name: 'Zero-based',
      categories: [
        CategoryModel(id: '_', name: 'Rent', pct: 35, color: AppColors.indigo),
        CategoryModel(id: '_', name: 'Food', pct: 15, color: AppColors.coral),
        CategoryModel(id: '_', name: 'Transport', pct: 10, color: AppColors.amber),
        CategoryModel(id: '_', name: 'Fun', pct: 15, color: AppColors.violet),
        CategoryModel(id: '_', name: 'Savings', pct: 15, color: AppColors.emerald),
        CategoryModel(id: '_', name: 'Buffer', pct: 10, color: AppColors.slate),
      ],
    ),
    PresetBudget(
      name: 'Saver',
      categories: [
        CategoryModel(id: '_', name: 'Essentials', pct: 45, color: AppColors.indigo),
        CategoryModel(id: '_', name: 'Lifestyle', pct: 15, color: AppColors.violet),
        CategoryModel(id: '_', name: 'Savings', pct: 40, color: AppColors.emerald),
      ],
    ),
  ];

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05140F0F),
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x14140F0F),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      );
}
