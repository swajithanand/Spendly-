import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';
import '../widgets/filter_chip.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _periods = ['week', 'month', 'year', 'custom', 'all'];
  static const _labels = ['Week', 'Month', 'Year', 'Custom', 'All'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final period = state.insightsPeriod;
    final txs = state.filtered(period,
        from: state.insightsFrom, to: state.insightsTo);
    final total = txs.fold(0.0, (s, t) => s + t.amount);

    // Per-category aggregation
    final perCat = state.categories.map((c) {
      final cTxs = txs.where((t) => t.categoryId == c.id).toList();
      return _CatData(
        cat: c,
        spent: cTxs.fold(0.0, (s, t) => s + t.amount),
        count: cTxs.length,
        txs: cTxs,
      );
    }).toList();

    // Selected category for breakdown
    final selectedId = state.insightsSelectedCatId ??
        (state.categories.isNotEmpty ? state.categories.first.id : null);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INSIGHTS', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Where it ', style: AppTextStyles.displayLarge),
                      TextSpan(
                          text: 'goes.',
                          style: AppTextStyles.displayLargeItalic),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Filter bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => SpendlyFilterChip(
                  label: _labels[i],
                  active: period == _periods[i],
                  onTap: () =>
                      context.read<AppState>().setInsightsPeriod(_periods[i]),
                ),
              ),
            ),
          ),

          // Custom range
          if (period == 'custom')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _DateRangeRow(
                  from: state.insightsFrom,
                  to: state.insightsTo,
                  onChanged: (f, t) =>
                      context.read<AppState>().setInsightsRange(f, t),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Donut chart card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DonutCard(
                  perCat: perCat, total: total, period: period, state: state),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),

          // Breakdown section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text('BREAKDOWN BY CATEGORY',
                  style: AppTextStyles.eyebrow),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat = state.categories[i];
                  final active = cat.id == selectedId;
                  return GestureDetector(
                    onTap: () => context.read<AppState>().setInsightsCat(cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : AppColors.surface,
                        border: Border.all(
                            color: active ? AppColors.ink : AppColors.hairline),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFFAF8F2)
                                  : cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            cat.name,
                            style: AppTextStyles.bodySmallMedium.copyWith(
                                color: active
                                    ? const Color(0xFFFAF8F2)
                                    : AppColors.ink2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Breakdown card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverToBoxAdapter(
              child: _BreakdownCard(
                selectedId: selectedId,
                txs: txs,
                state: state,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _CatData {
  final CategoryModel cat;
  final double spent;
  final int count;
  final List<TransactionModel> txs;
  _CatData(
      {required this.cat,
      required this.spent,
      required this.count,
      required this.txs});
}

// ── Donut card ────────────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final List<_CatData> perCat;
  final double total;
  final String period;
  final AppState state;

  const _DonutCard({
    required this.perCat,
    required this.total,
    required this.period,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final sym = state.currencySymbol;
    final hasData = total > 0;

    final sections = hasData
        ? perCat
            .where((d) => d.spent > 0)
            .map((d) => PieChartSectionData(
                  value: d.spent,
                  color: d.cat.color,
                  radius: 36,
                  title: '',
                  badgePositionPercentageOffset: 0,
                ))
            .toList()
        : [
            PieChartSectionData(
              value: 1,
              color: AppColors.surface2,
              radius: 36,
              title: '',
            )
          ];

    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Donut
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 64,
                    sectionsSpace: hasData ? 2 : 0,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TOTAL', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: sym,
                            style: AppTextStyles.numericMedium.copyWith(
                                fontSize: 18, color: AppColors.muted)),
                        TextSpan(
                            text: fmt.format(total),
                            style:
                                AppTextStyles.numericMedium.copyWith(fontSize: 28)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _periodLabel(period, state),
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          ...perCat.map((d) {
            final pct = total > 0 ? d.spent / total * 100 : 0.0;
            return GestureDetector(
              onTap: () => context.read<AppState>().setInsightsCat(d.cat.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: d.cat.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(d.cat.name,
                          style: AppTextStyles.bodyMedium),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sym${fmt.format(d.spent)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _periodLabel(String period, AppState state) {
    final now = DateTime.now();
    switch (period) {
      case 'week': return 'Last 7 days';
      case 'month': return DateFormat('MMMM yyyy').format(now);
      case 'year': return '${now.year}';
      case 'all': return 'All time';
      case 'custom':
        if (state.insightsFrom != null && state.insightsTo != null) {
          final f = DateFormat('MMM d').format(state.insightsFrom!);
          final t = DateFormat('MMM d').format(state.insightsTo!);
          return '$f – $t';
        }
        return 'Custom';
      default: return '';
    }
  }
}

// ── Breakdown card ────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final String? selectedId;
  final List<TransactionModel> txs;
  final AppState state;

  const _BreakdownCard(
      {required this.selectedId, required this.txs, required this.state});

  @override
  Widget build(BuildContext context) {
    final cat = selectedId != null
        ? state.categories
            .where((c) => c.id == selectedId)
            .firstOrNull
        : null;
    if (cat == null) return const SizedBox.shrink();

    final cTxs = txs.where((t) => t.categoryId == cat.id).toList();
    final catTotal = cTxs.fold(0.0, (s, t) => s + t.amount);
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final sym = state.currencySymbol;

    // Group by subcategory, with per-label detail inside each group
    final groups = <String, _SubcatGroup>{};
    for (final t in cTxs) {
      final key = t.subcategory.isEmpty ? '__other' : t.subcategory;
      final display = t.subcategory.isEmpty ? 'Other' : t.subcategory;
      final g = groups.putIfAbsent(key, () => _SubcatGroup(display: display));
      g.total += t.amount;
      g.count += 1;

      final labelKey = t.label.trim().toLowerCase().isEmpty
          ? '__untagged'
          : t.label.trim().toLowerCase();
      final labelDisplay = t.label.trim().isEmpty ? 'Untagged' : t.label.trim();
      final lg = g.labels.putIfAbsent(
          labelKey, () => _LabelGroup(display: labelDisplay));
      lg.total += t.amount;
      lg.count += 1;
    }
    final sorted = groups.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final maxAmt = sorted.isEmpty ? 1.0 : sorted.first.total;

    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: cat.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(cat.name, style: AppTextStyles.bodySemiBold)),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: '$sym${fmt.format(catTotal)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.ink,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ])),
                  TextSpan(
                      text: ' · ${cTxs.length} tx${cTxs.length == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall),
                ]),
              ),
            ],
          ),

          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text('No transactions for this period.',
                      style: AppTextStyles.bodySmall)),
            )
          else
            ...sorted.asMap().entries.map((e) {
              final g = e.value;
              final pct = catTotal > 0 ? g.total / catTotal * 100 : 0.0;
              final barPct = g.total / math.max(maxAmt, 1);
              final labels = g.labels.values.toList()
                ..sort((a, b) => b.total.compareTo(a.total));
              return _SubcatRow(
                label: g.display,
                count: g.count,
                pct: pct,
                amount: g.total,
                barPct: barPct,
                color: cat.color,
                isFirst: e.key == 0,
                fmt: fmt,
                currencySymbol: sym,
                labels: labels,
              );
            }),
        ],
      ),
    );
  }
}

class _LabelGroup {
  final String display;
  double total = 0;
  int count = 0;
  _LabelGroup({required this.display});
}

class _SubcatGroup {
  final String display;
  double total = 0;
  int count = 0;
  final Map<String, _LabelGroup> labels = {};
  _SubcatGroup({required this.display});
}

class _SubcatRow extends StatefulWidget {
  final String label;
  final int count;
  final double pct;
  final double amount;
  final double barPct;
  final Color color;
  final bool isFirst;
  final NumberFormat fmt;
  final String currencySymbol;
  final List<_LabelGroup> labels;

  const _SubcatRow({
    required this.label,
    required this.count,
    required this.pct,
    required this.amount,
    required this.barPct,
    required this.color,
    required this.isFirst,
    required this.fmt,
    required this.currencySymbol,
    required this.labels,
  });

  @override
  State<_SubcatRow> createState() => _SubcatRowState();
}

class _SubcatRowState extends State<_SubcatRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0, end: widget.barPct)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: widget.isFirst
              ? null
              : const Border(top: BorderSide(color: AppColors.hairlineSoft)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.muted2,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.count} tx · ${widget.pct.toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.currencySymbol}${widget.fmt.format(widget.amount)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontFeatures: [const FontFeature.tabularFigures()]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _anim.value,
                    backgroundColor: AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
            // Per-label detail, shown when expanded
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Column(
                  children: widget.labels.map((g) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              g.display,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${g.count} tx',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.muted2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${widget.currencySymbol}${widget.fmt.format(g.total)}',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontFeatures: [
                                  const FontFeature.tabularFigures()
                                ]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _DateRangeRow extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final Function(DateTime, DateTime) onChanged;
  const _DateRangeRow(
      {required this.from, required this.to, required this.onChanged});

  Future<void> _pick(BuildContext context, bool isFrom) async {
    final init = isFrom ? (from ?? DateTime.now()) : (to ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    onChanged(
        isFrom ? picked : (from ?? DateTime.now()),
        isFrom ? (to ?? DateTime.now()) : picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pick(context, true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 2),
                  Text(from != null ? fmt.format(from!) : 'Select',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppColors.muted2, size: 18),
          Expanded(
            child: GestureDetector(
              onTap: () => _pick(context, false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TO', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 2),
                  Text(to != null ? fmt.format(to!) : 'Select',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
