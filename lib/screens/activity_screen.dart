import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/csv_exporter.dart';
import '../core/text_styles.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/filter_chip.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const _periods = ['week', 'month', 'year', 'custom', 'all'];
  static const _labels = ['Week', 'Month', 'Year', 'Custom', 'All'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final period = state.activityPeriod;
    final txs = state.filtered(period,
        from: state.activityFrom, to: state.activityTo)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final total = txs.fold(0.0, (s, t) => s + t.amount);

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
                  Text('HISTORY', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: 'All ',
                                style: AppTextStyles.displayLarge),
                            TextSpan(
                                text: 'activity.',
                                style: AppTextStyles.displayLargeItalic),
                          ]),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            txs.isEmpty ? null : () => _exportCsv(context, txs),
                        tooltip: 'Export CSV',
                        icon: const Icon(Icons.ios_share_rounded,
                            color: AppColors.ink2, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
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
                      context.read<AppState>().setActivityPeriod(_periods[i]),
                ),
              ),
            ),
          ),

          // Custom range picker
          if (period == 'custom')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _DateRangeRow(
                  from: state.activityFrom,
                  to: state.activityTo,
                  onChanged: (f, t) =>
                      context.read<AppState>().setActivityRange(f, t),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Summary card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SummaryCard(total: total, count: txs.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Transaction groups or empty
          if (txs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: AppConstants.cardDecoration,
                  child: const _EmptyState(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildGroups(context, txs),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(
      BuildContext context, List<TransactionModel> txs) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final csv = CsvExporter.build(txs, state.categories, state.user.currency);
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final name = 'spendly_${state.activityPeriod}_$stamp.csv';

    try {
      if (kIsWeb) {
        // Web: hand the file to the browser's share dialog (dart:io is
        // unavailable here, so build the file from bytes in memory).
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(csv),
              mimeType: 'text/csv',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: 'Spendly transactions',
        ));
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: write to temp and open the share sheet.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        await file.writeAsString(csv);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Spendly transactions',
        ));
      } else {
        // Desktop: save straight to the Downloads folder.
        final dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        await file.writeAsString(csv);
        _toast(messenger, 'Exported ${txs.length} transactions to ${file.path}');
      }
    } catch (e) {
      _toast(messenger, 'Export failed: $e');
    }
  }

  void _toast(ScaffoldMessengerState messenger, String msg) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppTextStyles.bodySmallMedium
                .copyWith(color: const Color(0xFFFAF8F2))),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<Widget> _buildGroups(
      BuildContext context, List<TransactionModel> txs) {
    final groups = <DateTime, List<TransactionModel>>{};
    for (final t in txs) {
      final day = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final sorted = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return sorted.map((day) {
      final items = groups[day]!;
      final dayTotal = items.fold(0.0, (s, t) => s + t.amount);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_relDay(day), style: AppTextStyles.bodyMedium),
                Text(
                  '${context.read<AppState>().currencySymbol}${NumberFormat('#,##0.##').format(dayTotal)} · ${items.length} item${items.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            decoration: AppConstants.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.map((t) => _TxRow(tx: t)).toList(),
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    }).toList();
  }

  String _relDay(DateTime d) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = todayDate.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('EEE, MMM d').format(d);
  }
}

// ── Date range row ────────────────────────────────────────────────────────────

class _DateRangeRow extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final Function(DateTime, DateTime) onChanged;

  const _DateRangeRow(
      {required this.from, required this.to, required this.onChanged});

  Future<void> _pick(BuildContext context, bool isFrom) async {
    final init = isFrom
        ? (from ?? DateTime.now())
        : (to ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    if (isFrom) {
      onChanged(picked, to ?? DateTime.now());
    } else {
      onChanged(from ?? DateTime.now(), picked);
    }
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
                  Text(
                    from != null ? fmt.format(from!) : 'Select',
                    style: AppTextStyles.bodyMedium,
                  ),
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
                  Text(
                    to != null ? fmt.format(to!) : 'Select',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double total;
  final int count;
  const _SummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final sym = context.watch<AppState>().currencySymbol;
    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL SPENT', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: sym,
                      style: AppTextStyles.numericMedium
                          .copyWith(fontSize: 20, color: AppColors.muted)),
                  TextSpan(
                      text: fmt.format(total),
                      style: AppTextStyles.numericMedium),
                ]),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count',
                  style: AppTextStyles.numericSmall),
              Text('transactions', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Transaction row ───────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final TransactionModel tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cat = state.categories.where((c) => c.id == tx.categoryId).firstOrNull;
    final isSavings = cat?.name.toLowerCase().contains('sav') ?? false;
    final fmt = NumberFormat('#,##0.##', 'en_US');
    final sym = state.currencySymbol;
    final time = DateFormat('h:mm a').format(tx.createdAt);

    return GestureDetector(
      onTap: () => showTransactionSheet(context, edit: tx),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cat?.color ?? AppColors.muted2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.label.isNotEmpty
                        ? tx.label
                        : (cat?.name ?? 'Transaction'),
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      cat?.name ?? '—',
                      if (tx.subcategory.isNotEmpty) tx.subcategory,
                      time,
                    ].join('  ·  '),
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isSavings ? '+' : '−'}$sym${fmt.format(tx.amount)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSavings ? AppColors.savingsText : AppColors.ink,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => context.read<AppState>().deleteTransaction(tx.id),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.muted2),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.surface2, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.muted, size: 20),
            ),
            const SizedBox(height: 10),
            Text('No transactions in this period.',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
}
