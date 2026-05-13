// lib/quick_add_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/ahorra_colors.dart';
import '../utils/categories.dart';
import 'ahorra_widgets.dart';
import '../utils/app_data.dart';
import '../models/models.dart';

class QuickAddModal extends StatefulWidget {
  final bool startAsExpense;
  const QuickAddModal({super.key, this.startAsExpense = false});

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  late bool _isExpense;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedWalletId;
  bool _categoryOpen = false;
  bool _walletOpen = false;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.startAsExpense;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _activeColor =>
      _isExpense ? const Color(0xFF8B2E2E) : AhorraColors.teal;

  void _submit(AppData data) {
    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a wallet'),
            backgroundColor: Colors.red),
      );
      return;
    }
    final wallet = data.wallets.firstWhere((w) => w.id == _selectedWalletId);
    final txn = Transaction(
      walletId: wallet.id,
      walletName: wallet.name,
      category: _selectedCategory ?? 'Other',
      description: _descCtrl.text.trim(),
      amount: amount,
      isExpense: _isExpense,
    );
    data.addTransaction(txn);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final wallets = data.wallets;
    final size = MediaQuery.of(context).size;
    final double hPad = size.width * 0.05;
    final double keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: keyboardH),
      decoration: const BoxDecoration(
        color: Color(0xFF1C4A47),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            hPad, size.height * 0.025, hPad, size.height * 0.04),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Add',
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

              // Income / Expense toggle
              Container(
                height: size.width * 0.115,
                decoration: BoxDecoration(
                    color: const Color(0xFF2A5A56),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    _ToggleTab(
                        label: 'Expense',
                        selected: _isExpense,
                        selectedColor: const Color(0xFF8B2E2E),
                        onTap: () => setState(() => _isExpense = true)),
                    _ToggleTab(
                        label: 'Income',
                        selected: !_isExpense,
                        selectedColor: AhorraColors.teal,
                        onTap: () => setState(() => _isExpense = false)),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.025),

              // Amount
              const ModalLabel('Amount'),
              FocusInputField(
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: size.height * 0.018),

              // Wallet selector
              const ModalLabel('Wallet'),
              if (wallets.isEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.01),
                  child: Text('No wallets yet. Add one first!',
                      style: TextStyle(
                          color: AhorraColors.textMuted,
                          fontSize: size.width * 0.033)),
                )
              else
                _DropdownField(
                  hint: 'Select wallet',
                  value:
                      wallets.where((w) => w.id == _selectedWalletId).isNotEmpty
                          ? wallets
                              .firstWhere((w) => w.id == _selectedWalletId)
                              .name
                          : null,
                  open: _walletOpen,
                  onToggle: () => setState(() {
                    _walletOpen = !_walletOpen;
                    _categoryOpen = false;
                  }),
                  items: wallets.map((w) => w.name).toList(),
                  onSelect: (name) {
                    final w = wallets.firstWhere((w) => w.name == name);
                    setState(() {
                      _selectedWalletId = w.id;
                      _walletOpen = false;
                    });
                  },
                  selected:
                      wallets.where((w) => w.id == _selectedWalletId).isNotEmpty
                          ? wallets
                              .firstWhere((w) => w.id == _selectedWalletId)
                              .name
                          : null,
                ),
              SizedBox(height: size.height * 0.018),

              // Category selector
              const ModalLabel('Category'),
              _DropdownField(
                hint: 'Select category',
                value: _selectedCategory,
                open: _categoryOpen,
                onToggle: () => setState(() {
                  _categoryOpen = !_categoryOpen;
                  _walletOpen = false;
                }),
                items: kCategories,
                onSelect: (cat) => setState(() {
                  _selectedCategory = cat;
                  _categoryOpen = false;
                }),
                selected: _selectedCategory,
              ),
              SizedBox(height: size.height * 0.018),

              // Description
              const ModalLabel('Description (optional)'),
              FocusInputField(controller: _descCtrl, hint: 'Add a note'),
              SizedBox(height: size.height * 0.03),

              // Submit
              SizedBox(
                width: double.infinity,
                height: size.width * 0.135,
                child: Material(
                  color: _activeColor,
                  borderRadius: BorderRadius.circular(size.width * 0.035),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(size.width * 0.035),
                    onTap: () => _submit(data),
                    child: Center(
                      child: Text(
                        _isExpense ? 'Add Expense' : 'Add Income',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.047,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dropdown field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final bool open;
  final VoidCallback onToggle;
  final List<String> items;
  final ValueChanged<String> onSelect;
  final String? selected;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.open,
    required this.onToggle,
    required this.items,
    required this.onSelect,
    required this.selected,
  });

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
                  value ?? hint,
                  style: TextStyle(
                    color: value != null
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
            constraints: BoxConstraints(maxHeight: w * 0.6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5A56),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(w * 0.03)),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: items.map((item) {
                  final bool isLast = item == items.last;
                  return GestureDetector(
                    onTap: () => onSelect(item),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04, vertical: w * 0.038),
                      decoration: BoxDecoration(
                        color: selected == item
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        border: const Border(
                          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
                        ),
                        borderRadius: isLast
                            ? BorderRadius.vertical(
                                bottom: Radius.circular(w * 0.03))
                            : null,
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: selected == item
                              ? AhorraColors.textWhite
                              : AhorraColors.textLight,
                          fontSize: w * 0.038,
                          fontWeight: selected == item
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

// ─── Toggle Tab ───────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

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
            color: selected ? selectedColor : Colors.transparent,
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
