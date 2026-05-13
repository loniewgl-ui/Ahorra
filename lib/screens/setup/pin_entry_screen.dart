import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../utils/app_data.dart'; // needed for Provider
import '../../widgets/main_nav.dart';
import '../auth/welcome_screen.dart'; // to navigate after reset

class PinEntryScreen extends StatefulWidget {
  final String? uid;
  const PinEntryScreen({super.key, this.uid});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  int _attempts = 0;

  String get _uid => widget.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _uid;
      if (uid.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
        return;
      }
      final storedHash = prefs.getString('pin_$uid');
      if (storedHash == null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNav()),
          (route) => false,
        );
        return;
      }

      final enteredHash = _hashPin(pin);
      if (enteredHash == storedHash) {
        if (!mounted) return;
        final appData = context.read<AppData>();
        await appData.load();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNav()),
          (route) => false,
        );
      } else {
        _attempts++;
        if (_attempts >= 3) {
          final prefs2 = await SharedPreferences.getInstance();
          await prefs2.remove('lastUid');
          await prefs2.remove('pin_$uid');
          try { await FirebaseAuth.instance.signOut(); } catch (_) {}
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wrong PIN. ${3 - _attempts} attempts left.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verifying PIN')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
          'To reset your PIN, you will be signed out and must log in again with your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out & Reset',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = _uid;
    final appData = context.read<AppData>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pin_$uid');
    await prefs.remove('lastUid');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'pinHash': FieldValue.delete()});
    } catch (_) {}
    await appData.clearAll();
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2E2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Enter Your PIN',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Attempts remaining: ${3 - _attempts}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, letterSpacing: 12),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: const TextStyle(
                      color: Colors.white24, fontSize: 28, letterSpacing: 12),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: !_obscure,
                    onChanged: (val) => setState(() => _obscure = !val!),
                    activeColor: Colors.white,
                    checkColor: const Color(0xFF0D2E2B),
                  ),
                  const Text('Show PIN',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6460),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Unlock', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _forgotPin,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
