import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/inventory_rules.dart';
import '../core/text_styles.dart';
import '../models/inventory_item.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';
import 'inventory_item_sheet.dart';

/// After a new spending is saved: if it looks like something kept at home
/// (groceries, an appliance, medicine…), offer to add it to the inventory.
///
/// The user can add the details now, ask to be reminded later (the purchase
/// then waits on the Inventory tab), or decline.
///
/// [context] must still be mounted, e.g. the navigator's context, not the
/// context of a sheet that has just been closed.
Future<void> offerInventoryFor(BuildContext context, TransactionModel tx) async {
  final kind = InventoryRules.kindFor(tx);
  if (kind == null) return;
  final state = context.read<AppState>();
  final name = InventoryRules.nameFor(tx);

  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.muted2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text('${kind.emoji}  Add to home inventory?',
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Track how much "$name" you have and when it '
                '${kind.defaultDueType == DueType.service ? 'needs servicing' : kind.defaultDueType == DueType.expiry ? 'expires' : 'needs attention'}.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: () => Navigator.pop(sheetCtx, _Choice.now),
                  color: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  child: Text('Add details now', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx, _Choice.later),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.hairline),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Remind me later',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.ink)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetCtx, _Choice.no),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('No thanks',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.muted)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (!context.mounted) return;
  switch (choice) {
    case _Choice.now:
      // Keep a reminder until the item is actually saved, so backing out of
      // the form half-way does not lose the purchase.
      state.deferInventory(tx);
      await showInventoryItemSheet(context,
          name: name, kind: kind, txId: tx.id);
    case _Choice.later:
      state.deferInventory(tx);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Saved as a reminder on the Inventory tab'),
          duration: Duration(seconds: 3),
        ));
    case _Choice.no:
    case null:
      // Swiping the sheet away is treated as "not now", with no reminder.
      break;
  }
}

enum _Choice { now, later, no }
