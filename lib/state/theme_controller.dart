import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/colors.dart';

/// Holds the selected colour theme and saves it between launches.
///
/// Call [load] before `runApp` so the first frame already uses the saved
/// theme.
class ThemeController extends ChangeNotifier {
  static const prefsKey = 'themeId';

  String _themeId;

  /// Creates a controller on [themeId] (Paper when omitted or unknown) and
  /// makes that theme the active one.
  ThemeController([String? themeId]) : _themeId = AppThemes.byId(themeId).id {
    AppColors.current = theme.palette;
  }

  /// Reads the saved choice. Falls back to Paper if nothing is saved, the
  /// saved id is unknown, or storage cannot be read.
  static Future<ThemeController> load() async {
    String? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(prefsKey);
    } catch (e) {
      debugPrint('ThemeController: could not read saved theme: $e');
    }
    return ThemeController(saved);
  }

  String get themeId => _themeId;
  AppThemeOption get theme => AppThemes.byId(_themeId);

  /// Switches to the theme with this id and saves the choice. Unknown ids
  /// are ignored.
  Future<void> setTheme(String id) async {
    final next = AppThemes.byId(id);
    if (next.id != id || id == _themeId) return;
    _themeId = id;
    AppColors.current = next.palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, id);
    } catch (e) {
      debugPrint('ThemeController: could not save theme: $e');
    }
  }
}
