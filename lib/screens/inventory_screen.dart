import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/inventory_item.dart';
import '../state/app_state.dart';
import '../widgets/filter_chip.dart';
import '../widgets/inventory_item_sheet.dart';

/// Home inventory: what is in the house, how much, and what needs attention
/// (expiring food, appliances due for service, reminders).
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  /// Null shows every kind.
  InventoryKind? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.inventory;
    final attention = state.inventoryAttention();
    final pending = state.pendingInventory;

    // Most urgent first, then alphabetical.
    int rank(InventoryItem i) => switch (i.status()) {
          DueStatus.overdue => 0,
          DueStatus.soon => 1,
          DueStatus.ok => 2,
          DueStatus.none => 3,
        };
    final items = all.where((i) => _filter == null || i.kind == _filter).toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        if (rank(a) < 3) return a.daysLeft()!.compareTo(b.daysLeft()!);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    // Only offer filters for kinds that are actually in use.
    final kindsInUse =
        InventoryKind.values.where((k) => all.any((i) => i.kind == k)).toList();

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
                  Text('AT HOME', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Your ', style: AppTextStyles.displayLarge),
                      TextSpan(
                          text: 'inventory.',
                          style: AppTextStyles.displayLargeItalic),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _SummaryCard(
                total: all.length,
                overdue: attention
                    .where((i) => i.status() == DueStatus.overdue)
                    .length,
                soon:
                    attention.where((i) => i.status() == DueStatus.soon).length,
              ),
            ),
          ),

          // Purchases waiting for details
          if (pending.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: _PendingCard(pending: pending),
              ),
            ),

          // Kind filter
          if (kindsInUse.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: kindsInUse.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return SpendlyFilterChip(
                          label: 'All',
                          active: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        );
                      }
                      final k = kindsInUse[i - 1];
                      return SpendlyFilterChip(
                        label: k.shortLabel,
                        active: _filter == k,
                        onTap: () => setState(() => _filter = k),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Items
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Container(
                  decoration: AppConstants.cardDecoration,
                  child: _EmptyState(filtered: all.isNotEmpty),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: AppConstants.cardDecoration,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _ItemRow(
                          key: ValueKey(items[i].id),
                          item: items[i],
                          isFirst: i == 0,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int total;
  final int overdue;
  final int soon;
  const _SummaryCard(
      {required this.total, required this.overdue, required this.soon});

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.numericSmall.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        );

    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          stat('$total', total == 1 ? 'item' : 'items', AppColors.ink),
          stat('$soon', 'due this week',
              soon > 0 ? AppColors.warningText : AppColors.ink),
          stat('$overdue', 'overdue',
              overdue > 0 ? AppColors.dangerText : AppColors.ink),
        ],
      ),
    );
  }
}

// ── Pending purchases ─────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final List<PendingInventory> pending;
  const _PendingCard({required this.pending});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 16, color: AppColors.warningText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pending.length == 1
                      ? '1 purchase waiting for details'
                      : '${pending.length} purchases waiting for details',
                  style: AppTextStyles.bodySemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'You asked to be reminded to add these to your inventory.',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: 6),
          for (final p in pending)
            Row(
              children: [
                Text(p.kind.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        'Bought ${DateFormat('MMM d').format(p.purchasedAt)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => showInventoryItemSheet(
                    context,
                    name: p.name,
                    kind: p.kind,
                    txId: p.txId,
                  ),
                  child: Text('Add details',
                      style: AppTextStyles.bodySmallMedium
                          .copyWith(color: AppColors.ink)),
                ),
                IconButton(
                  onPressed: () => state.dismissPendingInventory(p.txId),
                  tooltip: 'Dismiss reminder',
                  icon:
                      Icon(Icons.close_rounded, size: 16, color: AppColors.muted2),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final InventoryItem item;
  final bool isFirst;
  const _ItemRow({required this.item, required this.isFirst, super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final status = item.status();
    final due = describeDue(item);
    final dueColor = switch (status) {
      DueStatus.overdue => AppColors.dangerText,
      DueStatus.soon => AppColors.warningText,
      _ => AppColors.muted,
    };
    // Whole units step by one; fractional amounts (0.5 kg) are edited in
    // the form instead.
    final step = item.quantity == item.quantity.roundToDouble() ? 1.0 : 0.0;

    return InkWell(
      onTap: () => showInventoryItemSheet(context, edit: item),
      child: Container(
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: AppColors.hairlineSoft)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(item.kind.emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: item.isOut ? AppColors.muted : AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isOut
                        ? 'Out of stock${due.isEmpty ? '' : '  ·  $due'}'
                        : (due.isEmpty ? item.kind.label : due),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: item.isOut && due.isEmpty
                          ? AppColors.muted
                          : dueColor,
                      fontWeight: status == DueStatus.overdue ||
                              status == DueStatus.soon
                          ? FontWeight.w500
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (step > 0)
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Use one',
                onTap: item.quantity > 0
                    ? () => state.adjustInventoryQuantity(item.id, -step)
                    : null,
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: Text(
                '${formatQuantity(item.quantity)} ${item.unit}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()]),
              ),
            ),
            if (step > 0)
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: 'Add one',
                onTap: () => state.adjustInventoryQuantity(item.id, step),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _StepButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon,
            size: 16, color: onTap == null ? AppColors.muted2 : AppColors.ink2),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  /// True when items exist but the current filter hides them all.
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.surface2, shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined,
                  color: AppColors.muted, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'Nothing of this type yet.'
                  : 'Nothing here yet. Tap + to add what you have at home: '
                      'food, appliances, medicine. Add an expiry or service '
                      'date and Spendly will flag it when it is due.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
