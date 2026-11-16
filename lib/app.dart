import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/colors.dart';
import 'screens/signin_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/main_shell.dart';
import 'state/app_state.dart';
import 'state/theme_controller.dart';

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().theme;
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(theme,
          fontFamily: GoogleFonts.dmSans().fontFamily),
      // Switch instantly: animating ThemeData would fade Material widgets
      // while everything painted from AppColors has already changed.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyleFor(theme),
        child: ThemeRebuilder(themeId: theme.id, child: child!),
      ),
      home: const _LaunchGate(),
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/setup': (_) => const SetupScreen(),
        '/main': (_) => const MainShell(),
      },
    );
  }
}

/// Status-bar style for [theme]: dark icons on light themes, light icons on
/// dark ones.
SystemUiOverlayStyle overlayStyleFor(AppThemeOption theme) {
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // Android
    statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    // iOS (describes the bar's background, so it is the other way round)
    statusBarBrightness: theme.brightness,
  );
}

/// Material theme for [theme]. Spendly paints most of its UI straight from
/// AppColors; this covers the stock Material pieces (dialogs, date picker,
/// snackbars, text fields, dropdown menus).
ThemeData buildThemeData(AppThemeOption theme, {String? fontFamily}) {
  final p = theme.palette;
  // Paper keeps the exact colour scheme the app has always had.
  final isPaper = theme.id == AppThemes.defaultId;
  final scheme = isPaper
      ? ColorScheme.fromSeed(seedColor: p.ink, surface: p.surface)
      : ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: theme.brightness,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.ink2,
          outline: p.muted,
          outlineVariant: p.hairline,
          // Dialog, date picker and menu backgrounds
          surfaceContainerLow: p.surface,
          surfaceContainer: p.surface,
          surfaceContainerHigh: theme.isDark ? p.surface2 : p.surface,
          surfaceContainerHighest: p.surface2,
          error: p.danger,
          // Snackbars
          inverseSurface: p.ink,
          onInverseSurface: p.onInk,
        );
  return ThemeData(
    useMaterial3: true,
    brightness: theme.brightness,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.surface,
    colorScheme: scheme,
    fontFamily: fontFamily,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      actionTextColor: isPaper ? null : p.onInk,
      behavior: SnackBarBehavior.floating,
    ),
    textSelectionTheme: isPaper
        ? null
        : TextSelectionThemeData(
            cursorColor: p.ink,
            selectionColor: p.accent.withValues(alpha: 0.35),
            selectionHandleColor: p.accent,
          ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Rebuilds every widget below it when the theme changes.
///
/// Most of the app reads AppColors directly and much of it is `const`, so
/// those widgets would not notice a new theme on their own. Marking every
/// element dirty (what hot reload does) repaints them in place without
/// touching navigation or widget state.
class ThemeRebuilder extends StatefulWidget {
  final String themeId;
  final Widget child;

  const ThemeRebuilder({super.key, required this.themeId, required this.child});

  @override
  State<ThemeRebuilder> createState() => _ThemeRebuilderState();
}

class _ThemeRebuilderState extends State<ThemeRebuilder> {
  late String _builtFor = widget.themeId;

  static void _markAll(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markAll);
  }

  @override
  Widget build(BuildContext context) {
    if (_builtFor != widget.themeId) {
      _builtFor = widget.themeId;
      // Element.visitChildren rather than context.visitChildElements: the
      // latter refuses to run during build. Marking descendants dirty from
      // an ancestor's build is allowed, and they rebuild later in this frame.
      (context as Element).visitChildren(_markAll);
    }
    return widget.child;
  }
}

/// First screen of the app. Waits for saved data, then shows sign-in,
/// onboarding, or the main app depending on where the user left off.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  // Chosen once, when loading finishes. Later navigation is done by the
  // screens themselves, so this must not switch underneath them.
  Widget? _screen;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_screen == null && state.loaded) {
      _screen = !state.signedIn
          ? const SignInScreen()
          : state.isOnboarding
              ? const SetupScreen()
              : const MainShell();
      final error = state.loadError;
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 8),
          ));
        });
      }
    }
    return _screen ??
        Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.ink),
          ),
        );
  }
}
