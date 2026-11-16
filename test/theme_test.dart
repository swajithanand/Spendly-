import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/app.dart';
import 'package:spendly/core/app_theme.dart';
import 'package:spendly/core/colors.dart';
import 'package:spendly/state/theme_controller.dart';

/// WCAG 2.x relative luminance of an opaque colour.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours (1 to 21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Reads a themed colour from AppColors although it is itself `const`,
/// like most widgets in the app.
class _BgProbe extends StatelessWidget {
  const _BgProbe();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.bg, child: const SizedBox.expand());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.current = AppPalette.paper;
  });

  tearDown(() => AppColors.current = AppPalette.paper);

  group('AppThemes', () {
    test('offers Paper, Midnight, Sage and Ocean, in that order', () {
      expect(AppThemes.all.map((t) => t.id),
          ['paper', 'midnight', 'sage', 'ocean']);
      expect(AppThemes.all.map((t) => t.name),
          ['Paper', 'Midnight', 'Sage', 'Ocean']);
    });

    test('ids and names are unique', () {
      final ids = AppThemes.all.map((t) => t.id).toSet();
      final names = AppThemes.all.map((t) => t.name).toSet();
      expect(ids.length, AppThemes.all.length);
      expect(names.length, AppThemes.all.length);
    });

    test('every theme defines every token', () {
      final expected = AppPalette.paper.tokens.keys.toSet();
      expect(expected.length, 28);
      for (final t in AppThemes.all) {
        expect(t.palette.tokens.keys.toSet(), expected, reason: t.id);
      }
    });

    test('text, surface and fill tokens are fully opaque', () {
      const translucent = {'tabBar', 'shadow', 'shadowSoft'};
      for (final t in AppThemes.all) {
        t.palette.tokens.forEach((name, color) {
          if (translucent.contains(name)) return;
          expect(color.a, 1.0, reason: '${t.id}.$name');
        });
      }
    });

    test('only Midnight is dark, and its background really is dark', () {
      for (final t in AppThemes.all) {
        expect(t.isDark, t.id == 'midnight', reason: t.id);
        final bgIsDark = _luminance(t.palette.bg) < 0.2;
        expect(bgIsDark, t.isDark, reason: t.id);
      }
    });

    test('Paper keeps the original colours', () {
      const p = AppPalette.paper;
      expect(p.bg, const Color(0xFFF2F0EA));
      expect(p.surface, const Color(0xFFFFFFFF));
      expect(p.surface2, const Color(0xFFF8F6F1));
      expect(p.ink, const Color(0xFF14130F));
      expect(p.ink2, const Color(0xFF2E2D28));
      expect(p.muted, const Color(0xFF8B8880));
      expect(p.hairline, const Color(0xFFE8E4DA));
      expect(p.onInk, const Color(0xFFFAF8F2));
      expect(p.tabBar, const Color(0xF0FFFFFF));
      expect(p.shadow, const Color(0x14140F0F));
      expect(p.shadowSoft, const Color(0x05140F0F));
      expect(p.danger, const Color(0xFFB8412B));
    });

    test('translucent onInk values match the literals they replaced', () {
      const onInk = Color(0xFFFAF8F2);
      expect(onInk.withValues(alpha: 0.55).toARGB32(), 0x8CFAF8F2);
      expect(onInk.withValues(alpha: 0.6).toARGB32(), 0x99FAF8F2);
      expect(onInk.withValues(alpha: 0.376).toARGB32(), 0x60FAF8F2);
      expect(onInk.withValues(alpha: 0.102).toARGB32(), 0x1AFAF8F2);
    });

    test('byId falls back to Paper for unknown ids', () {
      expect(AppThemes.byId('nope').id, 'paper');
      expect(AppThemes.byId(null).id, 'paper');
      expect(AppThemes.byId('ocean').id, 'ocean');
    });

    test('category colours do not change with the theme', () {
      final before = List.of(AppColors.palette);
      AppColors.current = AppPalette.midnight;
      expect(AppColors.palette, before);
      expect(AppColors.indigo, const Color(0xFF5B6CFF));
    });
  });

  group('contrast', () {
    for (final t in AppThemes.all) {
      final p = t.palette;

      test('${t.name}: body text is at least 4.5:1', () {
        expect(_contrast(p.ink, p.bg), greaterThanOrEqualTo(4.5),
            reason: 'ink on bg');
        expect(_contrast(p.ink, p.surface), greaterThanOrEqualTo(4.5),
            reason: 'ink on surface');
        expect(_contrast(p.ink, p.surface2), greaterThanOrEqualTo(4.5),
            reason: 'ink on surface2');
        expect(_contrast(p.onInk, p.ink), greaterThanOrEqualTo(4.5),
            reason: 'onInk on ink');
        expect(_contrast(p.onInkStrong, p.ink), greaterThanOrEqualTo(4.5),
            reason: 'onInkStrong on ink');
        expect(_contrast(p.ink2, p.surface), greaterThanOrEqualTo(4.5),
            reason: 'ink2 on surface');
      });

      test('${t.name}: status text is readable on its background', () {
        // Paper is the original look and is left exactly as it was; its
        // green pill measures 4.42:1. The newer themes must reach 4.5:1.
        final min = t.id == 'paper' ? 4.4 : 4.5;
        expect(_contrast(p.successText, p.successBg),
            greaterThanOrEqualTo(min),
            reason: 'success');
        expect(_contrast(p.warningText, p.warningBg),
            greaterThanOrEqualTo(min),
            reason: 'warning');
        expect(_contrast(p.dangerText, p.dangerBg), greaterThanOrEqualTo(min),
            reason: 'danger');
        expect(_contrast(p.successOnDark, p.ink), greaterThanOrEqualTo(4.5),
            reason: 'successOnDark on ink');
        expect(_contrast(p.warningOnDark, p.ink), greaterThanOrEqualTo(4.5),
            reason: 'warningOnDark on ink');
        expect(_contrast(p.dangerOnDark, p.ink), greaterThanOrEqualTo(4.5),
            reason: 'dangerOnDark on ink');
      });

      test('${t.name}: secondary text is at least 3:1', () {
        expect(_contrast(p.muted, p.bg), greaterThanOrEqualTo(3.0),
            reason: 'muted on bg');
        expect(_contrast(p.muted, p.surface), greaterThanOrEqualTo(3.0),
            reason: 'muted on surface');
      });
    }
  });

  group('ThemeController', () {
    test('default is Paper', () async {
      final c = await ThemeController.load();
      expect(c.themeId, 'paper');
      expect(c.theme.palette, same(AppPalette.paper));
      expect(AppColors.current, same(AppPalette.paper));
    });

    test('setTheme updates AppColors.current and notifies', () async {
      final c = await ThemeController.load();
      var notified = 0;
      c.addListener(() => notified++);

      await c.setTheme('midnight');

      expect(c.themeId, 'midnight');
      expect(AppColors.current, same(AppPalette.midnight));
      expect(AppColors.bg, AppPalette.midnight.bg);
      expect(AppColors.onInk, AppPalette.midnight.onInk);
      expect(notified, 1);
    });

    test('AppColors is already updated when listeners are called', () async {
      final c = await ThemeController.load();
      AppPalette? seen;
      c.addListener(() => seen = AppColors.current);
      await c.setTheme('sage');
      expect(seen, same(AppPalette.sage));
    });

    test('the choice is saved under "themeId" and restored', () async {
      final first = await ThemeController.load();
      await first.setTheme('ocean');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeId'), 'ocean');

      // Simulate a relaunch: colours start from the default again.
      AppColors.current = AppPalette.paper;
      final second = await ThemeController.load();
      expect(second.themeId, 'ocean');
      expect(AppColors.current, same(AppPalette.ocean));
    });

    test('every theme can be selected and restored', () async {
      for (final t in AppThemes.all.reversed) {
        final c = await ThemeController.load();
        await c.setTheme(t.id);
        final restored = await ThemeController.load();
        expect(restored.themeId, t.id);
        expect(AppColors.current, same(t.palette));
      }
    });

    test('an unknown saved id falls back to Paper', () async {
      SharedPreferences.setMockInitialValues({'themeId': 'neon'});
      final c = await ThemeController.load();
      expect(c.themeId, 'paper');
      expect(AppColors.current, same(AppPalette.paper));
    });

    test('setting an unknown id changes nothing', () async {
      final c = await ThemeController.load();
      await c.setTheme('sage');
      var notified = 0;
      c.addListener(() => notified++);

      await c.setTheme('neon');

      expect(c.themeId, 'sage');
      expect(AppColors.current, same(AppPalette.sage));
      expect(notified, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeId'), 'sage');
    });

    test('setting the current theme again does not notify', () async {
      final c = await ThemeController.load();
      var notified = 0;
      c.addListener(() => notified++);
      await c.setTheme('paper');
      expect(notified, 0);
    });
  });

  group('Material theme', () {
    test('brightness and key colours follow the palette', () {
      for (final t in AppThemes.all) {
        final data = buildThemeData(t);
        expect(data.brightness, t.brightness, reason: t.id);
        expect(data.colorScheme.brightness, t.brightness, reason: t.id);
        expect(data.scaffoldBackgroundColor, t.palette.bg, reason: t.id);
        expect(data.colorScheme.surface, t.palette.surface, reason: t.id);
        expect(data.snackBarTheme.backgroundColor, t.palette.ink,
            reason: t.id);
      }
    });

    test('dialog and date-picker text is readable in every theme', () {
      for (final t in AppThemes.all) {
        final s = buildThemeData(t).colorScheme;
        expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5),
            reason: '${t.id} onSurface/surface');
        expect(_contrast(s.onSurface, s.surfaceContainerHigh),
            greaterThanOrEqualTo(4.5),
            reason: '${t.id} onSurface/surfaceContainerHigh');
        expect(_contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5),
            reason: '${t.id} onPrimary/primary');
        expect(_contrast(s.primary, s.surfaceContainerHigh),
            greaterThanOrEqualTo(3.0),
            reason: '${t.id} primary/surfaceContainerHigh');
      }
    });

    test('status-bar icons are light only on the dark theme', () {
      for (final t in AppThemes.all) {
        expect(overlayStyleFor(t).statusBarIconBrightness,
            t.isDark ? Brightness.light : Brightness.dark,
            reason: t.id);
      }
    });
  });

  group('ThemeRebuilder', () {
    testWidgets('const widgets repaint and keep their state', (tester) async {
      final controller = ThemeController();

      Widget app() => ListenableBuilder(
            listenable: controller,
            builder: (_, __) => Directionality(
              textDirection: TextDirection.ltr,
              child: ThemeRebuilder(
                themeId: controller.themeId,
                child: const Stack(children: [_BgProbe(), _Counter()]),
              ),
            ),
          );

      Color probeColor() => tester
          .widget<ColoredBox>(find.descendant(
              of: find.byType(_BgProbe), matching: find.byType(ColoredBox)))
          .color;

      await tester.pumpWidget(app());
      expect(probeColor(), AppPalette.paper.bg);
      await tester.tap(find.text('taps: 0'));
      await tester.pump();
      expect(find.text('taps: 1'), findsOneWidget);

      // Not awaited: saving goes through a platform channel, which does not
      // complete inside the widget tester's fake-async zone. The colours
      // and listeners are updated synchronously.
      controller.setTheme('midnight');
      await tester.pump();

      expect(probeColor(), AppPalette.midnight.bg);
      expect(find.text('taps: 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Stands in for on-screen state (scroll position, typed text, the open
/// Settings page) that a theme change must not reset.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _taps++),
        child: Text('taps: $_taps'),
      );
}
