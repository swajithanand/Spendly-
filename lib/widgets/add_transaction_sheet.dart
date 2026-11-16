import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';
import 'inventory_prompt.dart';

/// Opens the transaction sheet. Pass [edit] to edit an existing transaction;
/// omit it to create a new one.
void showTransactionSheet(BuildContext context, {TransactionModel? edit}) {
  final state = context.read<AppState>();
  if (edit != null) {
    state.openDraftForEdit(edit);
  } else {
    state.openDraft();
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: state,
      child: const AddTransactionSheet(),
    ),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelCtrl.text = context.read<AppState>().draft.label;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    state.draftSetLabel(_labelCtrl.text.trim());
    final isEdit = state.draft.editingId != null;
    final created = state.saveTransaction();
    final navigator = Navigator.of(context);
    navigator.pop();
    _showToast(context, state, isEdit);
    // A new purchase of something kept at home (groceries, an appliance…)
    // can go straight into the home inventory, now or as a reminder.
    if (created != null) offerInventoryFor(navigator.context, created);
  }

  void _showToast(BuildContext context, AppState state, bool isEdit) {
    final cat = state.categories
        .where((c) => c.id == state.draft.categoryId)
        .firstOrNull;
    if (cat == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(isEdit ? 'Updated · ${cat.name}' : 'Logged to ${cat.name}',
                style: AppTextStyles.bodySmallMedium
                    .copyWith(color: AppColors.onInk)),
          ],
        ),
        backgroundColor: AppColors.ink,
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = context.watch<AppState>().draft.editingId != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.muted2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
              child: Row(
                children: [
                  Text(isEdit ? 'Edit transaction' : 'New transaction',
                      style: AppTextStyles.displayMedium
                          .copyWith(fontSize: 26)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.ink2, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // Details scroll away; amount + keypad + save stay pinned below.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _AmountDisplay(),
                    const SizedBox(height: 12),
                    _CategoryChips(),
                    const SizedBox(height: 12),
                    _SubcategoryChips(),
                    const SizedBox(height: 12),
                    _LabelDateRow(ctrl: _labelCtrl),
                  ],
                ),
              ),
            ),

            // Keypad pinned at the bottom, in the thumb zone
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Keypad(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: _SaveButton(onTap: _save, isEdit: isEdit),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Amount display ────────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AppState>().draft;
    final isEmpty = draft.amount == '0';

    final sym = context.watch<AppState>().currencySymbol;
    return Container(
      width: double.infinity,
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      child: Column(
        children: [
          Text('AMOUNT', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: sym,
                style: AppTextStyles.amountSheet.copyWith(
                    fontSize: 28,
                    color: isEmpty ? AppColors.muted2 : AppColors.muted),
              ),
              TextSpan(
                text: draft.amount,
                style: AppTextStyles.amountSheet
                    .copyWith(color: isEmpty ? AppColors.muted2 : AppColors.ink),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', 'del',
  ];

  @override
  Widget build(BuildContext context) {
    // Fixed key height. Sizing keys from their width made the keypad fill
    // the whole sheet in a wide or short window (desktop, landscape) and
    // pushed the category pickers out of view.
    // The keys shrink on short screens so that roughly 300px stays free for
    // the amount, category and subcategory cards above (header and save
    // button take about 180px together).
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyHeight = ((screenHeight - 480) / 4).clamp(34.0, 56.0);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: keyHeight,
      ),
      children: _keys.map((k) => _Key(k: k)).toList(),
    );
  }
}

class _Key extends StatelessWidget {
  final String k;
  const _Key({required this.k});

  @override
  Widget build(BuildContext context) {
    final isDel = k == 'del';
    return GestureDetector(
      onTap: () => context.read<AppState>().draftKeyPress(k),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.shadowSoft, offset: const Offset(0, 1)),
          ],
        ),
        child: Center(
          child: isDel
              ? Icon(Icons.backspace_outlined,
                  size: 20, color: AppColors.muted2)
              : Text(
                  k,
                  style: AppTextStyles.keypad,
                ),
        ),
      ),
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      width: double.infinity,
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CATEGORY', style: AppTextStyles.eyebrow),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = state.categories[i];
                final active = cat.id == state.draft.categoryId;
                return GestureDetector(
                  onTap: () => state.draftSetCategory(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.surface : AppColors.surface2,
                      border: Border.all(
                        color: active ? AppColors.ink : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: cat.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.name,
                          style: AppTextStyles.bodySmallMedium
                              .copyWith(color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subcategory chips ─────────────────────────────────────────────────────────

class _SubcategoryChips extends StatelessWidget {
  static const _emojiChoices = [
    '😀', '😎', '🥳', '🤑', '☕', '🍕', '🍜', '🍺',
    '🎮', '🎁', '🐶', '🐱', '👶', '💄', '🔧', '🧾',
    '⚽', '🎸', '🌱', '💼', '✂️', '❤️', '⭐', '🏷️',
  ];

  Future<void> _createSubcategory(BuildContext context) async {
    final state = context.read<AppState>();
    final ctrl = TextEditingController();
    var emoji = _emojiChoices.last;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New subcategory',
              style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'e.g. Pets, Kids, Hobbies…',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted2),
                ),
                onSubmitted: (v) => Navigator.pop(dialogCtx, (v, emoji)),
              ),
              const SizedBox(height: 16),
              Text('ICON', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _emojiChoices.map((e) {
                    final selected = e == emoji;
                    return GestureDetector(
                      onTap: () => setDialogState(() => emoji = e),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.surface2
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? AppColors.ink
                                : AppColors.hairline,
                            width: selected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                            child:
                                Text(e, style: const TextStyle(fontSize: 18))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, (ctrl.text, emoji)),
              child: Text('Add',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      state.addCustomSubcategory(result.$1, emoji: result.$2);
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final draft = state.draft;
    final selected = draft.subcategory;

    // Show the selected/suggested one first, then the rest.
    final names = [
      if (selected.isNotEmpty) selected,
      ...state.allSubcategories.where((s) => s != selected),
    ];

    return Container(
      width: double.infinity,
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SUBCATEGORY', style: AppTextStyles.eyebrow),
              if (selected.isNotEmpty && !draft.subcatManual) ...[
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome,
                    size: 12, color: AppColors.muted),
                const SizedBox(width: 3),
                Text('auto-detected',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11, color: AppColors.muted)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: names.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                // Leading "+ New" chip creates a custom subcategory.
                if (i == 0) {
                  return GestureDetector(
                    onTap: () => _createSubcategory(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              size: 13, color: AppColors.ink2),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: AppTextStyles.bodySmallMedium
                                .copyWith(color: AppColors.ink2),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final name = names[i - 1];
                final active = name == selected;
                return GestureDetector(
                  onTap: () =>
                      context.read<AppState>().draftSetSubcategory(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.ink : AppColors.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.subcatEmoji(name),
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          name,
                          style: AppTextStyles.bodySmallMedium.copyWith(
                              color: active
                                  ? AppColors.onInk
                                  : AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Label + date row ──────────────────────────────────────────────────────────

class _LabelDateRow extends StatelessWidget {
  final TextEditingController ctrl;
  const _LabelDateRow({required this.ctrl});

  Future<void> _pickDate(BuildContext context) async {
    final state = context.read<AppState>();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.draft.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) state.draftSetDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = context.watch<AppState>().draft.date ?? DateTime.now();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          Expanded(
            child: Container(
              decoration: AppConstants.cardDecoration,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LABEL', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  // Flexible absorbs sub-pixel height rounding inside
                  // IntrinsicHeight so the card never overflows.
                  Flexible(
                    child: TextField(
                      controller: ctrl,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Groceries, Spotify…',
                        hintStyle: AppTextStyles.body
                            .copyWith(color: AppColors.muted2),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (v) =>
                          context.read<AppState>().draftSetLabel(v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Date
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              decoration: AppConstants.cardDecoration,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATE', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(DateFormat('MMM d').format(date),
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.muted),
                    ],
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

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isEdit;
  const _SaveButton({required this.onTap, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final valid = context.watch<AppState>().draftIsValid;
    return SizedBox(
      width: double.infinity,
      child: MaterialButton(
        onPressed: valid ? onTap : null,
        color: AppColors.ink,
        disabledColor: AppColors.ink.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        child: Text(isEdit ? 'Save changes' : 'Save transaction',
            style: AppTextStyles.button),
      ),
    );
  }
}
