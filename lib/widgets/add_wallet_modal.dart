// lib/add_wallet_modal.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';
import 'ahorra_widgets.dart';
import '../models/models.dart';

class AddWalletModal extends StatefulWidget {
  const AddWalletModal({super.key});

  @override
  State<AddWalletModal> createState() => _AddWalletModalState();
}

class _AddWalletModalState extends State<AddWalletModal> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _balanceCtrl = TextEditingController();
  WalletType _selectedType = WalletType.savings;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name =
        _nameCtrl.text.trim().isEmpty ? 'My Wallet' : _nameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0.0;
    Navigator.of(context).pop(
      Wallet(name: name, type: _selectedType, balance: balance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = size.width * 0.05;
    final double keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: keyboardH),
      decoration: const BoxDecoration(
        color: Color(0xFF1C4A47),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          hPad, size.height * 0.025, hPad, size.height * 0.04),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Wallet',
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
          const ModalLabel('Wallet Name'),
          FocusInputField(controller: _nameCtrl, hint: 'e.g. Main Wallet'),
          SizedBox(height: size.height * 0.02),
          const ModalLabel('Wallet Type'),
          _WalletTypeGrid(
            selected: _selectedType,
            onSelect: (t) => setState(() => _selectedType = t),
          ),
          SizedBox(height: size.height * 0.02),
          const ModalLabel('Starting Balance'),
          FocusInputField(
            controller: _balanceCtrl,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  child: Text('Add Wallet',
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
    );
  }
}

// ─── Wallet Type Grid ─────────────────────────────────────────────────────────

class _WalletTypeGrid extends StatelessWidget {
  final WalletType selected;
  final ValueChanged<WalletType> onSelect;

  const _WalletTypeGrid({required this.selected, required this.onSelect});

  static const List<WalletType> _row1 = [
    WalletType.savings,
    WalletType.cash,
    WalletType.credit
  ];
  static const List<WalletType> _row2 = [
    WalletType.investment,
    WalletType.check
  ];

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          children: _row1
              .map((t) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: t != WalletType.credit ? w * 0.02 : 0),
                      child: _TypeChip(
                          type: t,
                          selected: selected == t,
                          onTap: () => onSelect(t)),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: w * 0.02),
        Row(
          children: [
            ..._row2.map((t) => Padding(
                  padding: EdgeInsets.only(right: w * 0.02),
                  child: _TypeChip(
                      type: t,
                      selected: selected == t,
                      onTap: () => onSelect(t)),
                )),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final WalletType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            EdgeInsets.symmetric(vertical: w * 0.025, horizontal: w * 0.02),
        decoration: BoxDecoration(
          color: selected ? AhorraColors.teal : const Color(0xFF2A5A56),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: const Color(0xFF4A90D9), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.icon, style: TextStyle(fontSize: w * 0.055)),
            SizedBox(height: w * 0.01),
            Text(
              type.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.028,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
