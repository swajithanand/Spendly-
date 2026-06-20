import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';
import '../state/app_state.dart';
import '../widgets/add_transaction_sheet.dart';
import 'home_screen.dart';
import 'activity_screen.dart';
import 'insights_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [HomeScreen(), ActivityScreen(), InsightsScreen()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: state.activeTab,
        children: _screens,
      ),
      floatingActionButton: _SpendlyFab(
        onTap: () => showTransactionSheet(context),
      ),
      bottomNavigationBar: _SpendlyTabBar(
        current: state.activeTab,
        onTap: (i) => context.read<AppState>().setTab(i),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _SpendlyFab extends StatelessWidget {
  final VoidCallback onTap;
  const _SpendlyFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.ink,
      foregroundColor: const Color(0xFFFAF8F2),
      elevation: 8,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 26),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _SpendlyTabBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _SpendlyTabBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF0FFFFFF),
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14140F0F),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _TabItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                active: current == 0,
                onTap: () => onTap(0),
              ),
              _TabItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Activity',
                active: current == 1,
                onTap: () => onTap(1),
              ),
              _TabItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Insights',
                active: current == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.muted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 24 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(active ? activeIcon : icon,
                  key: ValueKey(active), color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.eyebrow.copyWith(
                color: color,
                letterSpacing: 0.5,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
