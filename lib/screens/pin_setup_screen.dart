import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/ahorra_colors.dart';
import '../widgets/main_nav.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4‑6 digit PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final hashed = _hashPin(pin);
      await prefs.setString('pin_$uid', hashed);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNav()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save PIN')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = size.width * 0.08;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: size.width * 0.2,
                    height: size.width * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(size.width * 0.05),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AhorraColors.textWhite,
                      size: 36,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                // Title
                Text(
                  'Create Your Security PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AhorraColors.textWhite,
                    fontSize: size.width * 0.065,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: size.height * 0.015),

                // Subtitle
                Text(
                  'You’ll need this PIN every time you open the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AhorraColors.textMuted,
                    fontSize: size.width * 0.038,
                  ),
                ),
                SizedBox(height: size.height * 0.05),

                // PIN Input field (styled like Ahorra)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.width * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _pinController,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: size.width * 0.08,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: AhorraColors.hintGrey,
                        fontSize: size.width * 0.08,
                        letterSpacing: 12,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // Show PIN checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: !_obscure,
                      onChanged: (val) => setState(() => _obscure = !val!),
                      activeColor: AhorraColors.teal,
                      checkColor: Colors.white,
                      side: const BorderSide(color: AhorraColors.textMuted),
                    ),
                    Text(
                      'Show PIN',
                      style: TextStyle(
                        color: AhorraColors.textLight,
                        fontSize: size.width * 0.038,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.045),

                // Set PIN button
                SizedBox(
                  height: size.height * 0.065,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AhorraColors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AhorraColors.teal.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Set PIN',
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
