import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // needed for TapGestureRecognizer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../widgets/ahorra_widgets.dart';
import 'signup_screen.dart';
import '../widgets/main_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please enter email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update lastSignIn timestamp in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'lastSignIn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      final appData = context.read<AppData>();
      await appData.load();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNav()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Unable to sign in.');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final double hPad = size.width * 0.065;
    final double topInset = media.padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: (topInset * 0.45) + (size.height * 0.018)),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: size.width * 0.048,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Center(
                child: Column(
                  children: [
                    AhorraWalletIcon(size: size.width * 0.22, gradient: true),
                    SizedBox(height: size.height * 0.02),
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: size.width * 0.07,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      'Sign in to continue managing your money.',
                      style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: AhorraColors.textMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.035),
              const AhorraFormLabel('Email'),
              AhorraInputField(
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              SizedBox(height: size.height * 0.018),
              const AhorraFormLabel('Password'),
              AhorraInputField(
                hint: 'Enter your password',
                obscure: true,
                controller: _passwordController,
              ),
              SizedBox(height: size.height * 0.03),
              AhorraPrimaryButton(
                label: 'Sign In',
                backgroundColor: AhorraColors.teal,
                textColor: Colors.white,
                isLoading: _isLoading,
                onTap: _isLoading ? null : _signIn,
              ),
              SizedBox(height: size.height * 0.025),
              // ─── CORRECTED: perfectly aligned "Create one" link ─────────
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                      fontSize: size.width * 0.034,
                      color: const Color(0xFF555555),
                    ),
                    children: [
                      TextSpan(
                        text: 'Create one',
                        style: TextStyle(
                          fontSize: size.width * 0.034,
                          color: AhorraColors.linkTeal,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
