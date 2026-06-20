import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFF2F0EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF8F6F1);
  static const Color ink = Color(0xFF14130F);
  static const Color ink2 = Color(0xFF2E2D28);
  static const Color muted = Color(0xFF8B8880);
  static const Color muted2 = Color(0xFFC3BFB5);
  static const Color hairline = Color(0xFFE8E4DA);
  static const Color hairlineSoft = Color(0xFFEFEBE1);

  // Category palette
  static const Color indigo = Color(0xFF5B6CFF);
  static const Color coral = Color(0xFFF26B5A);
  static const Color emerald = Color(0xFF2BB47B);
  static const Color amber = Color(0xFFE8A33A);
  static const Color violet = Color(0xFF9A6BE8);
  static const Color teal = Color(0xFF1FA9A7);
  static const Color pink = Color(0xFFED5E96);
  static const Color slate = Color(0xFF5C7186);

  static const List<Color> palette = [
    indigo, coral, emerald, amber, violet, teal, pink, slate,
  ];

  static const List<String> paletteNames = [
    'Indigo', 'Coral', 'Emerald', 'Amber', 'Violet', 'Teal', 'Pink', 'Slate',
  ];

  // Semantic
  static const Color success = Color(0xFF2BB47B);
  static const Color successBg = Color(0xFFE6F4EC);
  static const Color successText = Color(0xFF1d7a52);
  static const Color warning = Color(0xFFE8A33A);
  static const Color warningBg = Color(0xFFFBF0DC);
  static const Color warningText = Color(0xFF96660F);
  static const Color danger = Color(0xFFb8412b);
  static const Color dangerBg = Color(0xFFFBE6E1);
  static const Color dangerText = Color(0xFF9c3a26);
  static const Color savingsText = Color(0xFF1d7a52);

  // Semantic, tuned for the dark overview card
  static const Color successOnDark = Color(0xFF8FD7B6);
  static const Color warningOnDark = Color(0xFFF0C685);
  static const Color dangerOnDark = Color(0xFFF2A492);
}
