import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/text_styles.dart';
import '../models/inventory_item.dart';
import '../state/app_state.dart';

/// Formats a quantity without a pointless ".0" ("2", "1.5").
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toStringAsFixed(0);
  return q.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}

/// Human description of an item's date relative to today, e.g.
/// "Expires in 3 days", "Service overdue by 2 days". Empty when no date.
String describeDue(InventoryItem item, [DateTime? now]) {
  final d = item.daysLeft(now);
  if (d == null) return '';
  String days(int n) => '$n day${n == 1 ? '' : 's'}';
  switch (item.dueType) {
    case DueType.expiry:
      if (d < 0) return 'Expired ${days(-d)} ago';
      if (d == 0) return 'Expires today';
      if (d == 1) return 'Expires tomorrow';
      if (d <= 30) return 'Expires in ${days(d)}';
      return 'Expires ${DateFormat('MMM d, yyyy').format(item.dueDate!)}';
    case DueType.service:
      if (d < 0) return 'Service overdue by ${days(-d)}';
      if (d == 0) return 'Service due today';
      if (d == 1) return 'Service due tomorrow';
      if (d <= 30) return 'Service due in ${days(d)}';
      return 'Service due ${DateFormat('MMM d, yyyy').format(item.dueDate!)}';
    case DueType.reminder:
      if (d < 0) return 'Reminder was ${days(-d)} ago';
      if (d == 0) return 'Reminder today';
      if (d == 1) return 'Reminder tomorrow';
      if (d <= 30) return 'Reminder in ${days(d)}';
      return 'Reminder ${DateFormat('MMM d, yyyy').format(item.dueDate!)}';
    case DueType.none:
      return '';
  }
}

/// Opens the add/edit form for an inventory item.
///
/// Pass [edit] to change an existing item. Otherwise a new item is created,
/// optionally prefilled from a purchase ([name], [kind], [txId]).
Future<void> showInventoryItemSheet(
  BuildContext context, {
  InventoryItem? edit,
  String? name,
  InventoryKind? kind,
  String? txId,
}) {
  final state = context.read<AppState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: state,
      child: _InventoryItemSheet(
        edit: edit,
        initialName: name,
        initialKind: kind,
        txId: txId,
      ),
    ),
  );
}

class _InventoryItemSheet extends StatefulWidget {
  final InventoryItem? edit;
  final String? initialName;
  final InventoryKind? initialKind;
  final String? txId;

  const _InventoryItemSheet({
    this.edit,
    this.initialName,
    this.initialKind,
    this.txId,
  });

  @override
  State<_InventoryItemSheet> createState() => _InventoryItemSheetState();
}

class _InventoryItemSheetState extends State<_InventoryItemSheet> {
  static const _units = ['pcs', 'pack', 'kg', 'g', 'L', 'ml', 'box', 'bottle'];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _noteCtrl;
  late InventoryKind _kind;
  late String _unit;
  late DueType _dueType;
  DateTime? _dueDate;
  // Once the user picks a date type themselves, changing the kind must not
  // override it.
  bool _dueTypeTouched = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _nameCtrl = TextEditingController(text: e?.name ?? widget.initialName ?? '');
    _qtyCtrl = TextEditingController(text: formatQuantity(e?.quantity ?? 1));
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? widget.initialKind ?? InventoryKind.food;
    _unit = e?.unit ?? 'pcs';
    _dueType = e?.dueType ?? _kind.defaultDueType;
    _dueDate = e?.dueDate;
    _dueTypeTouched = e != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;

  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

  void _bumpQty(double delta) {
    final q = (_qty + delta).clamp(0.0, 99999.0);
    setState(() => _qtyCtrl.text = formatQuantity(q));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_valid) return;
    final state = context.read<AppState>();
    final hasDate = _dueType != DueType.none && _dueDate != null;
    final e = widget.edit;
    if (e != null) {
      state.updateInventoryItem(e.copyWith(
        name: _nameCtrl.text.trim(),
        kind: _kind,
        quantity: _qty,
        unit: _unit,
        dueType: hasDate ? _dueType : DueType.none,
        dueDate: hasDate ? _dueDate : null,
        clearDueDate: !hasDate,
        note: _noteCtrl.text.trim(),
      ));
    } else {
      state.addInventoryItem(InventoryItem(
        name: _nameCtrl.text.trim(),
        kind: _kind,
        quantity: _qty,
        unit: _unit,
        dueType: hasDate ? _dueType : DueType.none,
        dueDate: hasDate ? _dueDate : null,
        note: _noteCtrl.text.trim(),
        txId: widget.txId,
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final item = widget.edit!;
    state.deleteInventoryItem(item.id);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed "${item.name}"',
            overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: state.undoDeleteInventoryItem,
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dueDate == null
        ? 'Pick a date'
        : DateFormat('EEE, MMM d, yyyy').format(_dueDate!);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.muted2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_isEdit ? 'Edit item' : 'Add to inventory',
                        style:
                            AppTextStyles.displayMedium.copyWith(fontSize: 26)),
                  ),
                  if (_isEdit)
                    IconButton(
                      onPressed: _delete,
                      tooltip: 'Remove item',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger, size: 20),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  children: [
                    // Name
                    _Card(
                      label: 'ITEM',
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: !_isEdit && _nameCtrl.text.isEmpty,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyMedium,
                        decoration: _deco('e.g. Milk, Washing machine'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kind
                    _Card(
                      label: 'TYPE',
                      child: _ChipRow<InventoryKind>(
                        values: InventoryKind.values,
                        selected: _kind,
                        labelOf: (k) => '${k.emoji}  ${k.shortLabel}',
                        onTap: (k) => setState(() {
                          _kind = k;
                          if (!_dueTypeTouched) _dueType = k.defaultDueType;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quantity
                    _Card(
                      label: 'HOW MANY',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _RoundButton(
                                icon: Icons.remove_rounded,
                                tooltip: 'One less',
                                onTap: () => _bumpQty(-1),
                              ),
                              SizedBox(
                                width: 84,
                                child: TextField(
                                  controller: _qtyCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d{0,5}(\.\d{0,2})?')),
                                  ],
                                  style: AppTextStyles.numericSmall,
                                  decoration: _deco('0'),
                                ),
                              ),
                              _RoundButton(
                                icon: Icons.add_rounded,
                                tooltip: 'One more',
                                onTap: () => _bumpQty(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _ChipRow<String>(
                            values: _units,
                            selected: _unit,
                            labelOf: (u) => u,
                            onTap: (u) => setState(() => _unit = u),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    _Card(
                      label: 'DATE TO REMEMBER',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ChipRow<DueType>(
                            values: DueType.values,
                            selected: _dueType,
                            labelOf: (t) => t.label,
                            onTap: (t) => setState(() {
                              _dueType = t;
                              _dueTypeTouched = true;
                            }),
                          ),
                          if (_dueType != DueType.none) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event_rounded,
                                        size: 16, color: AppColors.muted),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        dateLabel,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                            color: _dueDate == null
                                                ? AppColors.muted
                                                : AppColors.ink),
                                      ),
                                    ),
                                    if (_dueDate != null)
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _dueDate = null),
                                        child: Icon(Icons.close_rounded,
                                            size: 16, color: AppColors.muted2),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    _Card(
                      label: 'NOTE',
                      child: TextField(
                        controller: _noteCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 3,
                        style: AppTextStyles.body,
                        decoration:
                            _deco('Where it is kept, warranty, anything else'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: _valid ? _save : null,
                  color: AppColors.ink,
                  disabledColor: AppColors.ink.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  child: Text(_isEdit ? 'Save changes' : 'Add item',
                      style: AppTextStyles.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted2),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      );
}

class _Card extends StatelessWidget {
  final String label;
  final Widget child;
  const _Card({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: AppConstants.cardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 18, color: AppColors.ink2),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface2,
          shape: const CircleBorder(),
        ),
      );
}

/// Horizontally scrolling single-select chips.
class _ChipRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onTap;

  const _ChipRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final v = values[i];
          final active = v == selected;
          return GestureDetector(
            onTap: () => onTap(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.surface : AppColors.surface2,
                border: Border.all(
                  color: active ? AppColors.ink : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                labelOf(v),
                style: AppTextStyles.bodySmallMedium
                    .copyWith(color: AppColors.ink2),
              ),
            ),
          );
        },
      ),
    );
  }
}
