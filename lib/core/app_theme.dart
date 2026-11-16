import 'package:flutter/material.dart';

/// Every colour that changes with the selected theme.
///
/// Category colours (indigo, amber, ...) are deliberately not here: they are
/// saved to disk as user data, so they stay the same in every theme.
@immutable
class AppPalette {
  // Backgrounds and surfaces
  final Color bg;
  final Color surface;
  final Color surface2;

  /// Translucent surface behind the bottom tab bar.
  final Color tabBar;

  // Text and the strong "ink" fill used for primary buttons and the
  // Home overview card.
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color muted2;

  /// Content (text, icons) placed on top of [ink].
  final Color onInk;

  /// Highest-contrast content on [ink], for the hero number.
  final Color onInkStrong;

  // Lines
  final Color hairline;
  final Color hairlineSoft;

  // Shadows under cards and bars
  final Color shadow;
  final Color shadowSoft;

  /// Signature colour of the theme. Used for the theme preview and to seed
  /// Material widgets (dialogs, date picker).
  final Color accent;

  // Semantic
  final Color success;
  final Color successBg;
  final Color successText;
  final Color warning;
  final Color warningBg;
  final Color warningText;
  final Color danger;
  final Color dangerBg;
  final Color dangerText;
  final Color savingsText;

  // Semantic, tuned to sit on [ink] (the overview card). The names say
  // "OnDark" because ink is dark in the light themes.
  final Color successOnDark;
  final Color warningOnDark;
  final Color dangerOnDark;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.tabBar,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.muted2,
    required this.onInk,
    required this.onInkStrong,
    required this.hairline,
    required this.hairlineSoft,
    required this.shadow,
    required this.shadowSoft,
    required this.accent,
    required this.success,
    required this.successBg,
    required this.successText,
    required this.warning,
    required this.warningBg,
    required this.warningText,
    required this.danger,
    required this.dangerBg,
    required this.dangerText,
    required this.savingsText,
    required this.successOnDark,
    required this.warningOnDark,
    required this.dangerOnDark,
  });

  /// Every token by name. Used by tests to check that no theme is missing
  /// a colour, and handy for debugging.
  Map<String, Color> get tokens => {
        'bg': bg,
        'surface': surface,
        'surface2': surface2,
        'tabBar': tabBar,
        'ink': ink,
        'ink2': ink2,
        'muted': muted,
        'muted2': muted2,
        'onInk': onInk,
        'onInkStrong': onInkStrong,
        'hairline': hairline,
        'hairlineSoft': hairlineSoft,
        'shadow': shadow,
        'shadowSoft': shadowSoft,
        'accent': accent,
        'success': success,
        'successBg': successBg,
        'successText': successText,
        'warning': warning,
        'warningBg': warningBg,
        'warningText': warningText,
        'danger': danger,
        'dangerBg': dangerBg,
        'dangerText': dangerText,
        'savingsText': savingsText,
        'successOnDark': successOnDark,
        'warningOnDark': warningOnDark,
        'dangerOnDark': dangerOnDark,
      };

  /// Warm paper background, near-black ink. The original Spendly look.
  static const paper = AppPalette(
    bg: Color(0xFFF2F0EA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF8F6F1),
    tabBar: Color(0xF0FFFFFF),
    ink: Color(0xFF14130F),
    ink2: Color(0xFF2E2D28),
    muted: Color(0xFF8B8880),
    muted2: Color(0xFFC3BFB5),
    onInk: Color(0xFFFAF8F2),
    onInkStrong: Color(0xFFFFFFFF),
    hairline: Color(0xFFE8E4DA),
    hairlineSoft: Color(0xFFEFEBE1),
    shadow: Color(0x14140F0F),
    shadowSoft: Color(0x05140F0F),
    accent: Color(0xFFE8A33A),
    success: Color(0xFF2BB47B),
    successBg: Color(0xFFE6F4EC),
    successText: Color(0xFF1D7A52),
    warning: Color(0xFFE8A33A),
    warningBg: Color(0xFFFBF0DC),
    warningText: Color(0xFF96660F),
    danger: Color(0xFFB8412B),
    dangerBg: Color(0xFFFBE6E1),
    dangerText: Color(0xFF9C3A26),
    savingsText: Color(0xFF1D7A52),
    successOnDark: Color(0xFF8FD7B6),
    warningOnDark: Color(0xFFF0C685),
    dangerOnDark: Color(0xFFF2A492),
  );

  /// True dark. Ink flips to a warm off-white, so primary buttons and the
  /// overview card become light blocks on a dark page.
  static const midnight = AppPalette(
    bg: Color(0xFF111214),
    surface: Color(0xFF1B1D21),
    surface2: Color(0xFF25282D),
    tabBar: Color(0xF01B1D21),
    ink: Color(0xFFF1EEE6),
    ink2: Color(0xFFD6D2C8),
    muted: Color(0xFF9A978F),
    muted2: Color(0xFF65635D),
    onInk: Color(0xFF16171A),
    onInkStrong: Color(0xFF0A0B0C),
    hairline: Color(0xFF30333A),
    hairlineSoft: Color(0xFF282B30),
    shadow: Color(0x66000000),
    shadowSoft: Color(0x33000000),
    accent: Color(0xFF8C9BFF),
    success: Color(0xFF4CC592),
    successBg: Color(0xFF16332A),
    successText: Color(0xFF7FDDB3),
    warning: Color(0xFFE8A33A),
    warningBg: Color(0xFF3A2E17),
    warningText: Color(0xFFF0C685),
    danger: Color(0xFFEC7A63),
    dangerBg: Color(0xFF3D1F1A),
    dangerText: Color(0xFFF2A492),
    savingsText: Color(0xFF7FDDB3),
    // Ink is light here, so these are the darker text variants.
    successOnDark: Color(0xFF1D7A52),
    warningOnDark: Color(0xFF8A5C0A),
    dangerOnDark: Color(0xFF9C3A26),
  );

  /// Light, soft green tint.
  static const sage = AppPalette(
    bg: Color(0xFFE9EFE5),
    surface: Color(0xFFFBFDF9),
    surface2: Color(0xFFF1F5EC),
    tabBar: Color(0xF0FBFDF9),
    ink: Color(0xFF17231B),
    ink2: Color(0xFF2D3B31),
    muted: Color(0xFF718074),
    muted2: Color(0xFFB2BFB2),
    onInk: Color(0xFFF4F8F1),
    onInkStrong: Color(0xFFFFFFFF),
    hairline: Color(0xFFD8E1D3),
    hairlineSoft: Color(0xFFE2E9DD),
    shadow: Color(0x14101F14),
    shadowSoft: Color(0x05101F14),
    accent: Color(0xFF5A9A75),
    success: Color(0xFF2BB47B),
    successBg: Color(0xFFDDEFE2),
    successText: Color(0xFF196B48),
    warning: Color(0xFFE8A33A),
    warningBg: Color(0xFFF8EFD9),
    warningText: Color(0xFF8A5C0A),
    danger: Color(0xFFB8412B),
    dangerBg: Color(0xFFF8E4DE),
    dangerText: Color(0xFF9C3A26),
    savingsText: Color(0xFF196B48),
    successOnDark: Color(0xFF8FD7B6),
    warningOnDark: Color(0xFFF0C685),
    dangerOnDark: Color(0xFFF2A492),
  );

  /// Light, cool blue tint.
  static const ocean = AppPalette(
    bg: Color(0xFFE7EEF5),
    surface: Color(0xFFFBFDFF),
    surface2: Color(0xFFEFF4F9),
    tabBar: Color(0xF0FBFDFF),
    ink: Color(0xFF0F1D2C),
    ink2: Color(0xFF25374B),
    muted: Color(0xFF6C7C8E),
    muted2: Color(0xFFAEBBC9),
    onInk: Color(0xFFF2F7FC),
    onInkStrong: Color(0xFFFFFFFF),
    hairline: Color(0xFFD4DFEA),
    hairlineSoft: Color(0xFFDFE7EF),
    shadow: Color(0x140F1C2B),
    shadowSoft: Color(0x050F1C2B),
    accent: Color(0xFF3B86C6),
    success: Color(0xFF2BB47B),
    successBg: Color(0xFFDFF1E9),
    successText: Color(0xFF1D7A52),
    warning: Color(0xFFE8A33A),
    warningBg: Color(0xFFF9EFDA),
    warningText: Color(0xFF8A5C0A),
    danger: Color(0xFFB8412B),
    dangerBg: Color(0xFFF9E4DF),
    dangerText: Color(0xFF9C3A26),
    savingsText: Color(0xFF1D7A52),
    successOnDark: Color(0xFF8FD7B6),
    warningOnDark: Color(0xFFF0C685),
    dangerOnDark: Color(0xFFF2A492),
  );
}

/// One selectable theme.
@immutable
class AppThemeOption {
  /// Saved to disk. Never rename an id once shipped.
  final String id;
  final String name;
  final AppPalette palette;
  final Brightness brightness;

  const AppThemeOption({
    required this.id,
    required this.name,
    required this.palette,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;
}

class AppThemes {
  static const String defaultId = 'paper';

  static const List<AppThemeOption> all = [
    AppThemeOption(
      id: 'paper',
      name: 'Paper',
      palette: AppPalette.paper,
      brightness: Brightness.light,
    ),
    AppThemeOption(
      id: 'midnight',
      name: 'Midnight',
      palette: AppPalette.midnight,
      brightness: Brightness.dark,
    ),
    AppThemeOption(
      id: 'sage',
      name: 'Sage',
      palette: AppPalette.sage,
      brightness: Brightness.light,
    ),
    AppThemeOption(
      id: 'ocean',
      name: 'Ocean',
      palette: AppPalette.ocean,
      brightness: Brightness.light,
    ),
  ];

  /// The theme with this id, or Paper when the id is unknown (for example
  /// a theme saved by a newer version of the app).
  static AppThemeOption byId(String? id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
