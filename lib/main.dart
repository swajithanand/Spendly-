import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'state/theme_controller.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loaded before the first frame so the app never flashes the wrong theme.
  // SpendlyApp keeps the status-bar icons in step with later theme changes.
  final themeController = await ThemeController.load();
  SystemChrome.setSystemUIOverlayStyle(overlayStyleFor(themeController.theme));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: const SpendlyApp(),
    ),
  );
}
