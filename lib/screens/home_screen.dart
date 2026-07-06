import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/budget_status.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/category_model.dart';
import '../state/app_state.dart';
import '../widgets/add_transaction_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthTxs = state.filtered('month');
    final totalSpent = monthTxs.fold(0.0, (s, t) => s + t.amount);
    final remaining = state.income - totalSpent;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase(),
                          style: AppTextStyles.eyebrow,
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: 'Hello, ',
                                style: AppTextStyles.displayLarge),
                            TextSpan(
                                text: '${state.firstName}.',
                                style: AppTextStyles.displayLargeItalic),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<AppState>().isOnboarding = false;
                      Navigator.pushNamed(context, '/setup');
                    },
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.ink,
                      child: Text(
                        state.userInitials,
                        style: AppTextStyles.eyebrow.copyWith(
                          color: const Color(0xFFFAF8F2),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overview card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: _OverviewCard(
                spent: totalSpent,
                income: state.income,
                remaining: remaining,
                categories: state.categories,
              ),
            ),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text('CATEGORIES', style: AppTextStyles.eyebrow),
            ),
          ),

          // Category cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.separated(
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final cat = state.categories[i];
                final spent = state.monthSpentForCat(cat.id);
                final limit = state.income * cat.pct / 100;
                return _CategoryCard(
                  cat: cat,
                  spent: spent,
                  limit: limit,
                  onTap: () {
                    context.read<AppState>().openDraft(categoryId: cat.id);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AppState>(),
                        child: const AddTransactionSheet(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final double spent;
  final double income;
  final double remaining;
  final List<CategoryModel> categories;

  const _OverviewCard({
    required this.spent,
    required this.income,
    required this.remaining,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final state = context.watch<AppState>();
    final sym = state.currencySymbol;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT THIS MONTH',
            style: AppTextStyles.eyebrow
                .copyWith(color: const Color(0x8CFAF8F2)),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: sym,
                style: AppTextStyles.numericHero.copyWith(
                    fontSize: 24,
                    color: const Color(0x8CFAF8F2),
                    fontWeight: FontWeight.w400),
              ),
              TextSpan(
                text: fmt.format(spent),
                style: AppTextStyles.numericHero,
              ),
            ]),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'of ',
                style: AppTextStyles.bodySmall
                    .copyWith(color: const Color(0x99FAF8F2)),
              ),
              TextSpan(
                text: '$sym${fmt.format(income)}',
                style: AppTextStyles.bodySmallMedium
                    .copyWith(color: const Color(0xFFFAF8F2)),
              ),
              TextSpan(
                text: '  ·  ',
                style: AppTextStyles.bodySmall
                    .copyWith(color: const Color(0x60FAF8F2)),
              ),
              if (remaining >= 0)
                TextSpan(
                  text: '$sym${fmt.format(remaining)} remaining',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0x99FAF8F2)),
                )
              else
                TextSpan(
                  text: '$sym${fmt.format(remaining.abs())} over income',
                  style: AppTextStyles.bodySmallMedium
                      .copyWith(color: AppColors.dangerOnDark),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  ...categories.map((cat) {
                    final catSpent = state.monthSpentForCat(cat.id);
                    final pct = income > 0 ? (catSpent / income) : 0.0;
                    return Flexible(
                      flex: (pct * 1000).round(),
                      child: Container(color: cat.color),
                    );
                  }),
                  Flexible(
                    flex: income > 0
                        ? ((remaining / income) * 1000).round().clamp(0, 1000)
                        : 1000,
                    child: Container(
                        color: const Color(0x1AFAF8F2)),
                  ),
                ],
              ),
            ),
          ),

          // Status alerts
          ..._alertPills(state),
        ],
      ),
    );
  }

  List<Widget> _alertPills(AppState state) {
    final pills = <Widget>[];
    for (final cat in categories) {
      final spent = state.monthSpentForCat(cat.id);
      final limit = income * cat.pct / 100;
      final status = BudgetHealth.statusFor(
        spent: spent,
        limit: limit,
        isSavings: BudgetHealth.isSavings(cat),
      );
      final (fg, icon, label) = switch (status) {
        BudgetStatus.nearLimit => (
            AppColors.warningOnDark,
            Icons.warning_amber_rounded,
            '${cat.name} near limit'
          ),
        BudgetStatus.over => (
            AppColors.dangerOnDark,
            Icons.error_outline_rounded,
            '${cat.name} over budget'
          ),
        BudgetStatus.achieved => (
            AppColors.successOnDark,
            Icons.check_rounded,
            '${cat.name} target reached'
          ),
        BudgetStatus.onTrack => (null, null, null),
      };
      if (fg == null) continue;
      pills.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
            Text(
              label!,
              style: AppTextStyles.caption
                  .copyWith(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ));
    }
    if (pills.isEmpty) return [];
    return [
      const SizedBox(height: 14),
      Wrap(spacing: 6, runSpacing: 6, children: pills),
    ];
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BudgetStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      BudgetStatus.nearLimit => (
          AppColors.warningBg,
          AppColors.warningText,
          Icons.warning_amber_rounded,
          'Near limit'
        ),
      BudgetStatus.over => (
          AppColors.dangerBg,
          AppColors.dangerText,
          Icons.error_outline_rounded,
          'Over budget'
        ),
      BudgetStatus.achieved => (
          AppColors.successBg,
          AppColors.successText,
          Icons.check_rounded,
          'Target reached'
        ),
      BudgetStatus.onTrack => (
          AppColors.surface2,
          AppColors.muted,
          Icons.circle_outlined,
          'On track'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final CategoryModel cat;
  final double spent;
  final double limit;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.cat,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _progress = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _animate());
  }

  void _animate() {
    final target =
        widget.limit > 0 ? (widget.spent / widget.limit).clamp(0.0, 1.0) : 0.0;
    _progress =
        Tween<double>(begin: 0, end: target).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(_CategoryCard old) {
    super.didUpdateWidget(old);
    if (old.spent != widget.spent || old.limit != widget.limit) _animate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final sym = context.watch<AppState>().currencySymbol;
    final remaining = widget.limit - widget.spent;
    final isOver = remaining < 0;
    final pctUsed =
        widget.limit > 0 ? (widget.spent / widget.limit * 100).round() : 0;
    final status = BudgetHealth.statusFor(
      spent: widget.spent,
      limit: widget.limit,
      isSavings: BudgetHealth.isSavings(widget.cat),
    );
    final barColor = switch (status) {
      BudgetStatus.nearLimit => AppColors.warning,
      BudgetStatus.over => AppColors.danger,
      BudgetStatus.achieved => AppColors.success,
      BudgetStatus.onTrack => widget.cat.color,
    };
    final pctColor = switch (status) {
      BudgetStatus.nearLimit => AppColors.warningText,
      BudgetStatus.over => AppColors.dangerText,
      BudgetStatus.achieved => AppColors.successText,
      BudgetStatus.onTrack => null,
    };

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: AppConstants.cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: widget.cat.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(widget.cat.name,
                      style: AppTextStyles.bodySemiBold,
                      overflow: TextOverflow.ellipsis),
                ),
                if (status != BudgetStatus.onTrack) ...[
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${widget.cat.pct}%',
                      style: AppTextStyles.caption.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()])),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Numbers
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: sym,
                      style: AppTextStyles.numericLarge.copyWith(
                          fontSize: 16, color: AppColors.muted),
                    ),
                    TextSpan(
                      text: fmt.format(widget.spent),
                      style: AppTextStyles.numericLarge,
                    ),
                  ]),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'of ',
                        style: AppTextStyles.bodySmall),
                    TextSpan(
                        text: '$sym${fmt.format(widget.limit)}',
                        style: AppTextStyles.bodySmallMedium
                            .copyWith(color: AppColors.ink2)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _progress.value,
                    backgroundColor: AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Meta
            Row(
              children: [
                if (status == BudgetStatus.achieved)
                  Text(
                    isOver
                        ? 'Target reached · +$sym${fmt.format(remaining.abs())} extra'
                        : 'Target reached',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.successText,
                        fontWeight: FontWeight.w500),
                  )
                else if (isOver)
                  Text(
                    '$sym${fmt.format(remaining.abs())} over',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.danger),
                  )
                else
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '$sym${fmt.format(remaining)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.ink2,
                                fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                          text: ' left',
                          style: AppTextStyles.caption),
                    ]),
                  ),
                const Spacer(),
                Text('$pctUsed%',
                    style: AppTextStyles.caption.copyWith(
                        color: pctColor,
                        fontWeight: pctColor != null ? FontWeight.w600 : null)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
