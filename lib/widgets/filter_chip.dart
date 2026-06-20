import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';

class SpendlyFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const SpendlyFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          border: Border.all(color: active ? AppColors.ink : AppColors.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmallMedium.copyWith(
              color: active ? const Color(0xFFFAF8F2) : AppColors.ink2),
        ),
      ),
    );
  }
}
