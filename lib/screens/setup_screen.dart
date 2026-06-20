import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../core/currencies.dart';
import '../core/text_styles.dart';
import '../state/app_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      _nameCtrl.text = s.user.name;
      _emailCtrl.text = s.user.email;
      _incomeCtrl.text = s.income.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _done() {
    final s = context.read<AppState>();
    if (s.totalPct != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categories must add up to 100%')),
      );
      return;
    }
    s.completeSetup();
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isOnboarding = state.isOnboarding;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (!isOnboarding)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.ink),
                    ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: isOnboarding ? 'Welcome to ' : 'Settings',
                            style: AppTextStyles.displayMedium,
                          ),
                          TextSpan(
                            text: isOnboarding ? 'Spendly.' : '.',
                            style: AppTextStyles.displayMediumItalic,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14140F0F),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: AppTextStyles.bodySmallMedium
                      .copyWith(color: const Color(0xFFFAF8F2)),
                  unselectedLabelStyle:
                      AppTextStyles.bodySmallMedium.copyWith(color: AppColors.muted),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Income'),
                    Tab(text: 'Budget'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ProfilePane(nameCtrl: _nameCtrl, emailCtrl: _emailCtrl),
                  _IncomePane(incomeCtrl: _incomeCtrl),
                  const _BudgetPane(),
                ],
              ),
            ),

            // CTA button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.bg, Colors.transparent],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: _done,
                  color: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  child: Text(
                    isOnboarding ? 'Start tracking' : 'Save changes',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile pane ─────────────────────────────────────────────────────────────

class _ProfilePane extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;

  const _ProfilePane({required this.nameCtrl, required this.emailCtrl});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // Avatar card
          Container(
            decoration: AppConstants.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.ink,
                  child: Text(
                    state.userInitials,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: const Color(0xFFFAF8F2),
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.user.name, style: AppTextStyles.bodySemiBold),
                      const SizedBox(height: 2),
                      Text(state.user.email,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fields
          _FieldStack(children: [
            _FieldRow(
              label: 'Full name',
              child: TextField(
                controller: nameCtrl,
                style: AppTextStyles.body,
                decoration: _inputDeco('Your name'),
                onChanged: (v) => context.read<AppState>().updateProfile(name: v),
              ),
            ),
            _FieldRow(
              label: 'Email',
              child: TextField(
                controller: emailCtrl,
                style: AppTextStyles.body,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDeco('you@example.com'),
                onChanged: (v) => context.read<AppState>().updateProfile(email: v),
              ),
            ),
            _FieldRow(
              label: 'Currency',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: Currencies.all
                          .any((c) => c.code == state.user.currency)
                      ? state.user.currency
                      : Currencies.all.first.code,
                  isExpanded: true,
                  menuMaxHeight: 420,
                  style: AppTextStyles.body,
                  items: Currencies.all
                      .map((c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              '${c.code} — ${c.name} (${c.symbol})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      context.read<AppState>().updateProfile(currency: v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<AppState>().signOut();
                Navigator.pushReplacementNamed(context, '/signin');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.hairline),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.surface,
              ),
              child: Text('Sign out',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.danger)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Income pane ───────────────────────────────────────────────────────────────

class _IncomePane extends StatelessWidget {
  final TextEditingController incomeCtrl;

  const _IncomePane({required this.incomeCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Container(
            decoration: AppConstants.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly income (after tax)', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('\$',
                        style: AppTextStyles.displayMedium
                            .copyWith(color: AppColors.muted, fontSize: 28)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: incomeCtrl,
                        style: AppTextStyles.numericMedium
                            .copyWith(fontSize: 32, color: AppColors.ink),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (v) {
                          final parsed = double.tryParse(v) ?? 0;
                          context.read<AppState>().setIncome(parsed);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FieldStack(children: [
            _FieldRow(
              label: 'Pay schedule',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Monthly',
                  isExpanded: true,
                  style: AppTextStyles.body,
                  items: const [
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                        value: 'Twice a month', child: Text('Twice a month')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Irregular', child: Text('Irregular')),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
            _FieldRow(
              label: 'Cycle start',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: '1st',
                  isExpanded: true,
                  style: AppTextStyles.body,
                  items: const [
                    DropdownMenuItem(
                        value: '1st', child: Text('1st of the month')),
                    DropdownMenuItem(
                        value: '15th', child: Text('15th of the month')),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Budget pane ───────────────────────────────────────────────────────────────

class _BudgetPane extends StatelessWidget {
  const _BudgetPane();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final total = state.totalPct;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('QUICK START', style: AppTextStyles.eyebrow),
          ),

          // Presets
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = AppConstants.presets[i];
                return GestureDetector(
                  onTap: () => state.applyPreset(i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.hairline),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...p.categories.map((c) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                  color: c.color, shape: BoxShape.circle),
                            )),
                        const SizedBox(width: 6),
                        Text(p.name, style: AppTextStyles.bodySmallMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Categories header
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('CATEGORIES', style: AppTextStyles.eyebrow),
              ),
              const Spacer(),
              _AllocPill(total: total),
            ],
          ),
          const SizedBox(height: 10),

          // Category list
          Container(
            decoration: AppConstants.cardDecoration,
            child: Column(
              children: [
                ...state.categories.map(
                  (cat) => _CatRow(cat: cat, key: ValueKey(cat.id)),
                ),
                // Add category
                if (state.categories.length < 8)
                  InkWell(
                    onTap: state.addCategory,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(22)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.hairlineSoft)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.surface2,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                size: 14, color: AppColors.ink2),
                          ),
                          const SizedBox(width: 10),
                          Text('Add category',
                              style: AppTextStyles.bodySmallMedium),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocPill extends StatelessWidget {
  final int total;
  const _AllocPill({required this.total});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surface2;
    Color fg = AppColors.ink2;
    if (total == 100) { bg = AppColors.successBg; fg = AppColors.successText; }
    if (total > 100) { bg = AppColors.dangerBg; fg = AppColors.dangerText; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text('$total%',
          style: AppTextStyles.caption.copyWith(color: fg,
              fontFeatures: [const FontFeature.tabularFigures()])),
    );
  }
}

class _CatRow extends StatefulWidget {
  final dynamic cat;
  const _CatRow({required this.cat, super.key});

  @override
  State<_CatRow> createState() => _CatRowState();
}

class _CatRowState extends State<_CatRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pctCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cat.name);
    _pctCtrl = TextEditingController(text: '${widget.cat.pct}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  void _pickColor() async {
    final state = context.read<AppState>();
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(current: widget.cat.color),
    );
    if (color != null) state.updateCategoryColor(widget.cat.id, color);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final cat = widget.cat;
    final isFirst = state.categories.first.id == cat.id;

    return Container(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(
                top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Color swatch
          GestureDetector(
            onTap: _pickColor,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name input
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (v) => state.updateCategoryName(cat.id, v),
            ),
          ),

          // Pct input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 36,
                  child: TextField(
                    controller: _pctCtrl,
                    style: AppTextStyles.bodySemiBold.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()]),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (v) {
                      int n = int.tryParse(v) ?? 0;
                      if (n > 100) { n = 100; _pctCtrl.text = '100'; }
                      state.updateCategoryPct(cat.id, n);
                    },
                  ),
                ),
                Text('%',
                    style: AppTextStyles.bodySmallMedium
                        .copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete
          IconButton(
            onPressed: () => state.removeCategory(cat.id),
            icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatelessWidget {
  final Color current;
  const _ColorPickerDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppColors.palette.map((c) {
            final selected = c == current;
            return GestureDetector(
              onTap: () => Navigator.pop(context, c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? Border.all(color: AppColors.ink, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Shared field widgets ──────────────────────────────────────────────────────

class _FieldStack extends StatelessWidget {
  final List<Widget> children;
  const _FieldStack({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppConstants.cardDecoration,
        child: Column(children: children),
      );
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isFirst =
        context.findAncestorWidgetOfExactType<_FieldStack>()
                ?.children
                .first ==
            this;
    return Container(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted2),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
