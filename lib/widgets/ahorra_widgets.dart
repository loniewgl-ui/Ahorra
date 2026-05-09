// lib/ahorra_widgets.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';

// ─── Wallet Icon ──────────────────────────────────────────────────────────────

class AhorraWalletIcon extends StatelessWidget {
  final double? size;
  final bool gradient;

  const AhorraWalletIcon({super.key, this.size, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    final double s = size ?? MediaQuery.of(context).size.width * 0.28;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: gradient ? null : AhorraColors.iconBg,
        gradient: gradient
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A6460), Color(0xFF0D3533)],
              )
            : null,
        borderRadius: BorderRadius.circular(s * 0.22),
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_outlined,
          color: Colors.white,
          size: s * 0.48,
        ),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────

class AhorraPrimaryButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const AhorraPrimaryButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool enabled = onTap != null && !isLoading;
    final Color effectiveBg = enabled
        ? backgroundColor
        : Color.lerp(backgroundColor, Colors.grey.shade400, 0.45)!;

    return SizedBox(
      width: double.infinity,
      height: (w * 0.145).clamp(52.0, 62.0),
      child: Material(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(w * 0.04),
          onTap: enabled ? onTap : null,
          splashColor: Colors.white12,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: enabled ? 1 : 0.8,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: w * 0.06,
                      height: w * 0.06,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: w * 0.048,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form Label ───────────────────────────────────────────────────────────────

class AhorraFormLabel extends StatelessWidget {
  final String text;
  const AhorraFormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.02),
      child: Text(
        text,
        style: TextStyle(
          fontSize: w * 0.036,
          fontWeight: FontWeight.w600,
          color: AhorraColors.labelGrey,
        ),
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class AhorraInputField extends StatefulWidget {
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const AhorraInputField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  State<AhorraInputField> createState() => _AhorraInputFieldState();
}

class _AhorraInputFieldState extends State<AhorraInputField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  void didUpdateWidget(covariant AhorraInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscure != widget.obscure) {
      _isObscured = widget.obscure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      height: w * 0.13,
      decoration: BoxDecoration(
        color: AhorraColors.inputBg,
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        keyboardType: widget.keyboardType,
        style: TextStyle(fontSize: w * 0.036, color: const Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              TextStyle(fontSize: w * 0.034, color: AhorraColors.hintGrey),
          border: InputBorder.none,
          suffixIcon: widget.obscure
              ? IconButton(
                  onPressed: () {
                    setState(() => _isObscured = !_isObscured);
                  },
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: AhorraColors.hintGrey,
                    size: w * 0.05,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.035,
          ),
        ),
      ),
    );
  }
}

// ─── Feature Grid ─────────────────────────────────────────────────────────────

class AhorraFeatureGrid extends StatelessWidget {
  const AhorraFeatureGrid({super.key});

  static const List<_FeatureItem> _features = [
    _FeatureItem(
        icon: Icons.bar_chart_rounded, label: 'Visual spending analytics'),
    _FeatureItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Multiple wallet support'),
    _FeatureItem(
        icon: Icons.track_changes_rounded, label: 'Smart budget tracking'),
    _FeatureItem(icon: Icons.shield_outlined, label: 'Secure local storage'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: _features.map((f) => _FeatureCard(item: f)).toList(),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: AhorraColors.featureCardBg,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AhorraColors.featureCardBorder, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.03),
      child: Row(
        children: [
          Icon(item.icon, color: AhorraColors.textLight, size: w * 0.055),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                  color: AhorraColors.textLight,
                  fontSize: w * 0.031,
                  height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Modal Widgets ─────────────────────────────────────────────────────

class ModalLabel extends StatelessWidget {
  final String text;
  const ModalLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.02),
      child: Text(
        text,
        style: TextStyle(
          color: AhorraColors.textLight,
          fontSize: w * 0.036,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class FocusInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const FocusInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<FocusInputField> createState() => _FocusInputFieldState();
}

class _FocusInputFieldState extends State<FocusInputField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: w * 0.125,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEC),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: _focused ? const Color(0xFF4A90D9) : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        style: TextStyle(fontSize: w * 0.036, color: const Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              TextStyle(fontSize: w * 0.034, color: AhorraColors.hintGrey),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
        ),
      ),
    );
  }
}
