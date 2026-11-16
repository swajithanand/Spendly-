import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppColors {
  /// The active theme's colours. Set by ThemeController; everything below
  /// that is a getter reads from it, so those tokens are not compile-time
  /// constants and cannot be used inside `const` expressions.
  static AppPalette current = AppPalette.paper;

  static Color get bg => current.bg;
  static Color get surface => current.surface;
  static Color get surface2 => current.surface2;
  static Color get tabBar => current.tabBar;
  static Color get ink => current.ink;
  static Color get ink2 => current.ink2;
  static Color get muted => current.muted;
  static Color get muted2 => current.muted2;
  static Color get hairline => current.hairline;
  static Color get hairlineSoft => current.hairlineSoft;

  /// Content (text, icons) placed on top of [ink].
  static Color get onInk => current.onInk;
  static Color get onInkStrong => current.onInkStrong;

  static Color get shadow => current.shadow;
  static Color get shadowSoft => current.shadowSoft;
  static Color get accent => current.accent;

  // Category palette. Saved to disk as user data, so these are the same in
  // every theme.
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
  static Color get success => current.success;
  static Color get successBg => current.successBg;
  static Color get successText => current.successText;
  static Color get warning => current.warning;
  static Color get warningBg => current.warningBg;
  static Color get warningText => current.warningText;
  static Color get danger => current.danger;
  static Color get dangerBg => current.dangerBg;
  static Color get dangerText => current.dangerText;
  static Color get savingsText => current.savingsText;

  // Semantic, tuned for the overview card (drawn on ink)
  static Color get successOnDark => current.successOnDark;
  static Color get warningOnDark => current.warningOnDark;
  static Color get dangerOnDark => current.dangerOnDark;
}
