// lib/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/ahorra_colors.dart';
import '../widgets/ahorra_widgets.dart';
import '../utils/app_data.dart';
import '../models/models.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import '../widgets/quick_add_modal.dart' show kCategories;

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;

  void _openAddBudget() async {
    final Budget? result = await showModalBottomSheet<Budget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetModal(defaultPeriod: _selectedPeriod),
    );
    if (result != null && context.mounted) {
      context.read<AppData>().addBudget(result);
    }
  }

  void _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete the budget for "${budget.category}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AppData>().deleteBudget(budget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final filtered =
        data.budgets.where((b) => b.period == _selectedPeriod).toList();
    final double totalSpent =
        filtered.fold(0.0, (s, b) => s + data.spentForBudget(b));
    final double totalLimit = filtered.fold(0.0, (s, b) => s + b.limit);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _BudgetsHeader(
              topInset: topInset,
              totalSpent: totalSpent,
              totalLimit: totalLimit,
              budgetCount: filtered.length,
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              onAddBudget: _openAddBudget,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyBudgets(
                      period: _selectedPeriod, onAddBudget: _openAddBudget)
                  : _BudgetList(
                      budgets: filtered,
                      data: data,
                      onDeleteBudget: _deleteBudget,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: data.budgets.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'fab_budgets',
              onPressed: _openAddBudget,
              backgroundColor: AhorraColors.teal,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _BudgetsHeader extends StatelessWidget {
  final double topInset;
  final double totalSpent;
  final double totalLimit;
  final int budgetCount;
  final BudgetPeriod selectedPeriod;
  final ValueChanged<BudgetPeriod> onPeriodChanged;
  final VoidCallback onAddBudget;

  const _BudgetsHeader({
    required this.topInset,
    required this.totalSpent,
    required this.totalLimit,
    required this.budgetCount,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onAddBudget,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.05;
    final double pct =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(hPad,
          (topInset * 0.45) + (size.height * 0.012), hPad, size.height * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budgets',
                  style: TextStyle(
                      color: AhorraColors.textWhite,
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.w700)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen())),
                    child: Icon(Icons.notifications_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                  SizedBox(width: size.width * 0.04),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen())),
                    child: Icon(Icons.settings_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04, vertical: size.height * 0.015),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedPeriod == BudgetPeriod.monthly ? 'Monthly' : 'Weekly'} Spending',
                        style: TextStyle(
                            color: AhorraColors.textLight,
                            fontSize: size.width * 0.031),
                      ),
                      SizedBox(height: size.height * 0.006),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(totalSpent)}',
                        style: TextStyle(
                          color: AhorraColors.textWhite,
                          fontSize: size.width * 0.085,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.004),
                      Text(
                          'of ₱${NumberFormat('#,##0.00').format(totalLimit)} budgeted',
                          style: TextStyle(
                              color: AhorraColors.textMuted,
                              fontSize: size.width * 0.03)),
                      SizedBox(height: size.height * 0.01),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalSpent > totalLimit && totalLimit > 0
                                ? const Color(0xFFD94040)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onAddBudget,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.035,
                            vertical: size.height * 0.009),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E5),
                          borderRadius:
                              BorderRadius.circular(size.width * 0.05),
                        ),
                        child: Text('+ Add Budget',
                            style: TextStyle(
                                color: const Color(0xFF1A3A38),
                                fontSize: size.width * 0.032,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    _PeriodToggle(
                        selected: selectedPeriod, onChanged: onPeriodChanged),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.008),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onChanged;
  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      height: w * 0.09,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PTab(
              label: 'Monthly',
              sel: selected == BudgetPeriod.monthly,
              onTap: () => onChanged(BudgetPeriod.monthly)),
          _PTab(
              label: 'Weekly',
              sel: selected == BudgetPeriod.weekly,
              onTap: () => onChanged(BudgetPeriod.weekly)),
        ],
      ),
    );
  }
}

class _PTab extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  const _PTab({required this.label, required this.sel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        padding:
            EdgeInsets.symmetric(horizontal: w * 0.028, vertical: w * 0.015),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? AhorraColors.teal : AhorraColors.textLight,
            fontSize: w * 0.028,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Budget List (now with delete callback) ─────────────────────────────────

class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final AppData data;
  final Function(Budget) onDeleteBudget; // ADDED

  const _BudgetList({
    required this.budgets,
    required this.data,
    required this.onDeleteBudget, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.045, vertical: size.height * 0.02),
      children: [
        ...budgets.map((b) {
          final double spent = data.spentForBudget(b);
          return _BudgetCard(
            budget: b,
            spent: spent,
            onDelete: () => onDeleteBudget(b), // pass the callback
          );
        }),
        SizedBox(height: size.height * 0.04),
      ],
    );
  }
}

// ─── Budget Card (now with delete button) ───────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final VoidCallback onDelete; // ADDED

  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.onDelete, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double pct =
        budget.limit > 0 ? (spent / budget.limit).clamp(0.0, 1.0) : 0.0;
    final bool over = spent > budget.limit;
    final Color barCol = over ? const Color(0xFFD94040) : AhorraColors.teal;
    final double remaining = budget.limit - spent;

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.04),
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category,
                        style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A))),
                    SizedBox(height: w * 0.005),
                    Text(budget.period.label,
                        style: TextStyle(
                            fontSize: w * 0.03,
                            color: const Color(0xFF888888))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${NumberFormat('#,##0.00').format(spent)}',
                      style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                          color: over
                              ? const Color(0xFFD94040)
                              : const Color(0xFF1A1A1A))),
                  Text('of ₱${NumberFormat('#,##0.00').format(budget.limit)}',
                      style: TextStyle(
                          fontSize: w * 0.028, color: const Color(0xFF888888))),
                ],
              ),
              SizedBox(width: w * 0.02),
              // Delete button (same style as wallet delete)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: EdgeInsets.all(w * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: w * 0.055,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.02),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: w * 0.025,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(barCol),
            ),
          ),
          SizedBox(height: w * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                over
                    ? '₱${NumberFormat('#,##0.00').format(spent - budget.limit)} over budget'
                    : '₱${NumberFormat('#,##0.00').format(remaining)} remaining',
                style: TextStyle(
                  color:
                      over ? const Color(0xFFD94040) : const Color(0xFF2E9E5B),
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: const Color(0xFF888888), fontSize: w * 0.03)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyBudgets extends StatelessWidget {
  final BudgetPeriod period;
  final VoidCallback onAddBudget;
  const _EmptyBudgets({required this.period, required this.onAddBudget});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
              size: Size(w * 0.22, w * 0.22), painter: _TargetPainter()),
          SizedBox(height: w * 0.05),
          Text('No ${period.label} Budgets',
              style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          SizedBox(height: w * 0.015),
          Text('Set a budget to track spending by category.',
              style: TextStyle(
                  fontSize: w * 0.034, color: const Color(0xFF888888))),
          SizedBox(height: w * 0.06),
          GestureDetector(
            onTap: onAddBudget,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.07, vertical: w * 0.035),
              decoration: BoxDecoration(
                  color: AhorraColors.teal,
                  borderRadius: BorderRadius.circular(w * 0.04)),
              child: Text('+ Add Budget',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Budget Modal (unchanged) ─────────────────────────────────────────────

class AddBudgetModal extends StatefulWidget {
  final BudgetPeriod defaultPeriod;
  const AddBudgetModal({super.key, required this.defaultPeriod});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal> {
  final TextEditingController _limitCtrl = TextEditingController();
  late BudgetPeriod _period;
  String? _selectedCategory;
  bool _categoryOpen = false;

  @override
  void initState() {
    super.initState();
    _period = widget.defaultPeriod;
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final double limit = double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
    if (limit <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.of(context).pop(
      Budget(category: _selectedCategory!, limit: limit, period: _period),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.05;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: keyboardH),
      decoration: const BoxDecoration(
        color: Color(0xFF1C4A47),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          hPad, size.height * 0.025, hPad, size.height * 0.04),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Budget',
                    style: TextStyle(
                        color: AhorraColors.textWhite,
                        fontSize: size.width * 0.055,
                        fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('X',
                      style: TextStyle(
                          color: AhorraColors.textLight,
                          fontSize: size.width * 0.048,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.025),
            Container(
              height: size.width * 0.115,
              decoration: BoxDecoration(
                  color: const Color(0xFF2A5A56),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _ModalToggleTab(
                    label: 'Monthly',
                    selected: _period == BudgetPeriod.monthly,
                    onTap: () => setState(() => _period = BudgetPeriod.monthly),
                  ),
                  _ModalToggleTab(
                    label: 'Weekly',
                    selected: _period == BudgetPeriod.weekly,
                    onTap: () => setState(() => _period = BudgetPeriod.weekly),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.025),
            const ModalLabel('Category'),
            _CategoryDropdown(
              selected: _selectedCategory,
              open: _categoryOpen,
              onToggle: () => setState(() => _categoryOpen = !_categoryOpen),
              onSelect: (cat) => setState(() {
                _selectedCategory = cat;
                _categoryOpen = false;
              }),
            ),
            SizedBox(height: size.height * 0.02),
            const ModalLabel('Budget Limit'),
            FocusInputField(
              controller: _limitCtrl,
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: size.height * 0.03),
            SizedBox(
              width: double.infinity,
              height: size.width * 0.135,
              child: Material(
                color: AhorraColors.teal,
                borderRadius: BorderRadius.circular(size.width * 0.035),
                child: InkWell(
                  borderRadius: BorderRadius.circular(size.width * 0.035),
                  onTap: _submit,
                  child: Center(
                    child: Text('Set Budget',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.047,
                            fontWeight: FontWeight.w700)),
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

class _CategoryDropdown extends StatelessWidget {
  final String? selected;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;
  const _CategoryDropdown(
      {required this.selected,
      required this.open,
      required this.onToggle,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.038),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5A56),
              borderRadius: open
                  ? BorderRadius.vertical(top: Radius.circular(w * 0.03))
                  : BorderRadius.circular(w * 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected ?? 'Select category',
                  style: TextStyle(
                    color: selected != null
                        ? AhorraColors.textWhite
                        : AhorraColors.textMuted,
                    fontSize: w * 0.038,
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: AhorraColors.textLight, size: w * 0.055),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            constraints: BoxConstraints(maxHeight: w * 0.55),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5A56),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(w * 0.03)),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: kCategories.map((cat) {
                  final bool isLast = cat == kCategories.last;
                  return GestureDetector(
                    onTap: () => onSelect(cat),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04, vertical: w * 0.038),
                      decoration: BoxDecoration(
                        color: selected == cat
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent,
                        border: const Border(
                            top:
                                BorderSide(color: Color(0x14FFFFFF), width: 1)),
                        borderRadius: isLast
                            ? BorderRadius.vertical(
                                bottom: Radius.circular(w * 0.03))
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected == cat
                              ? AhorraColors.textWhite
                              : AhorraColors.textLight,
                          fontSize: w * 0.038,
                          fontWeight: selected == cat
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModalToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModalToggleTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AhorraColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AhorraColors.textMuted,
                fontSize: w * 0.038,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    final center = Offset(size.width / 2, size.height / 2);
    for (final r in [0.47, 0.33, 0.18]) {
      canvas.drawCircle(center, size.width * r, paint);
    }
    canvas.drawCircle(
        center, size.width * 0.07, Paint()..color = const Color(0xFFCCCCCC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
