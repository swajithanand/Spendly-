import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/colors.dart';
import 'screens/signin_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/main_shell.dart';

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          surface: AppColors.surface,
        ),
        fontFamily: GoogleFonts.dmSans().fontFamily,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/signin',
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/setup': (_) => const SetupScreen(),
        '/main': (_) => const MainShell(),
      },
    );
  }
}
