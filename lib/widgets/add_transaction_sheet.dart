import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';

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
    state.saveTransaction();
    Navigator.pop(context);
    _showToast(context, state, isEdit);
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
                    .copyWith(color: const Color(0xFFFAF8F2))),
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
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.ink2, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Amount display
                    _AmountDisplay(),
                    const SizedBox(height: 14),

                    // Keypad
                    _Keypad(),
                    const SizedBox(height: 14),

                    // Category chips
                    _CategoryChips(),
                    const SizedBox(height: 12),

                    // Label
                    _LabelField(ctrl: _labelCtrl),
                    const SizedBox(height: 12),

                    // Subcategory (auto-detected, tappable to override)
                    _SubcategoryChips(),
                    const SizedBox(height: 12),

                    // Date
                    _DateRow(),
                    const SizedBox(height: 14),

                    // Save button
                    _SaveButton(onTap: _save, isEdit: isEdit),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
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
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.7,
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
          boxShadow: const [
            BoxShadow(color: Color(0x05140F0F), offset: Offset(0, 1)),
          ],
        ),
        child: Center(
          child: isDel
              ? const Icon(Icons.backspace_outlined,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.categories.map((cat) {
              final active = cat.id == state.draft.categoryId;
              return GestureDetector(
                onTap: () => state.draftSetCategory(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
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
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Label field ───────────────────────────────────────────────────────────────

class _LabelField extends StatelessWidget {
  final TextEditingController ctrl;
  const _LabelField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppConstants.cardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LABEL', style: AppTextStyles.eyebrow),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. Groceries, Spotify…',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted2),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2),
            ),
            onChanged: (v) => context.read<AppState>().draftSetLabel(v),
          ),
        ],
      ),
    );
  }
}

// ── Subcategory chips ─────────────────────────────────────────────────────────

class _SubcategoryChips extends StatelessWidget {
  Future<void> _createSubcategory(BuildContext context) async {
    final state = context.read<AppState>();
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New subcategory',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'e.g. Pets, Kids, Hobbies…',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted2),
          ),
          onSubmitted: (v) => Navigator.pop(dialogCtx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
            child: Text('Add',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
          ),
        ],
      ),
    );
    if (name != null) state.addCustomSubcategory(name);
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
                const Icon(Icons.auto_awesome,
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
                          const Icon(Icons.add,
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
                    child: Text(
                      name,
                      style: AppTextStyles.bodySmallMedium.copyWith(
                          color: active
                              ? const Color(0xFFFAF8F2)
                              : AppColors.ink2),
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

// ── Date row ──────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  Future<void> _pick(BuildContext context) async {
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
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        decoration: AppConstants.cardDecoration,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DATE', style: AppTextStyles.eyebrow),
                const SizedBox(height: 4),
                Text(DateFormat('EEE, MMM d, yyyy').format(date),
                    style: AppTextStyles.bodyMedium),
              ],
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.muted),
          ],
        ),
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
