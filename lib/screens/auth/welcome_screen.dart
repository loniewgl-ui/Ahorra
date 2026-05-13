// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../utils/ahorra_colors.dart';
import '../../utils/app_data.dart';
import '../setup/terms_screen.dart';
import '../setup/pin_setup_screen.dart';
import '../setup/pin_entry_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => TermsModal(
        onAccept: () {
          if (!mounted) return;
          Navigator.push(
            dialogContext,
            MaterialPageRoute(builder: (_) => const SignUpScreen()),
          );
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _navigateToMain() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        (route) => false,
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final localPin = prefs.getString('pin_$uid');
    if (localPin != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinEntryScreen()),
        (route) => false,
      );
      return;
    }
    String? firebasePin;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      firebasePin = doc.data()?['pinHash'] as String?;
    } catch (_) {}
    if (firebasePin != null) {
      await prefs.setString('pin_$uid', firebasePin);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinEntryScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': userCredential.user!.email ?? '',
        'displayName': userCredential.user!.displayName ?? '',
        'photoUrl': userCredential.user!.photoURL ?? '',
        'authProvider': 'google',
        'lastSignIn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      await context.read<AppData>().load();
      if (!mounted) return;
      _navigateToMain();
    } on FirebaseAuthException catch (e) {
      _showError('Sign-in failed: ${e.message}');
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook sign-in coming soon'),
        backgroundColor: AhorraColors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final double hPad = size.width * 0.065;
    final double topInset = media.padding.top;
    final double bottomInset = media.padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
              ),
            ),
          ),

          // Content
          SafeArea(
            top: false,
            bottom: false,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    topInset + size.height * 0.07,
                    hPad,
                    bottomInset + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: size.width * 0.2,
                        height: size.width * 0.2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(size.width * 0.05),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: size.width * 0.1,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.025),

                      // Welcome label
                      Text(
                        'WELCOME TO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: size.width * 0.03,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: size.height * 0.006),

                      // App name
                      Text(
                        'Ahorra',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.016),

                      // Description
                      Text(
                        'Track expenses, manage wallets,\nand take control of your finances.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: size.width * 0.034,
                          height: 1.65,
                        ),
                      ),
                      SizedBox(height: size.height * 0.055),

                      // Feature pills
                      Wrap(
                        spacing: size.width * 0.025,
                        runSpacing: size.width * 0.025,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeaturePill(
                              icon: Icons.wallet_outlined,
                              label: 'Multi-wallet'),
                          _FeaturePill(
                              icon: Icons.pie_chart_outline, label: 'Budgets'),
                          _FeaturePill(
                              icon: Icons.trending_up, label: 'Analytics'),
                          _FeaturePill(
                              icon: Icons.receipt_long_outlined,
                              label: 'Transactions'),
                        ],
                      ),
                      SizedBox(height: size.height * 0.055),

                      // Get Started button
                      _WelcomeButton(
                        label: 'Get Started',
                        backgroundColor: const Color(0xFFE8E8E3),
                        textColor: const Color(0xFF1A3A38),
                        onTap: () => _showTerms(context),
                      ),
                      SizedBox(height: size.height * 0.014),

                      // Sign In button
                      _WelcomeButton(
                        label: 'Sign In',
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        textColor: Colors.white,
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        onTap: _navigateToLogin,
                      ),
                      SizedBox(height: size.height * 0.03),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.15),
                                thickness: 0.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: size.width * 0.03,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.15),
                                thickness: 0.5),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),

                      // Social buttons row
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              svgAsset: 'assets/icons/google_logo.svg',
                              label: 'Google',
                              onTap: _isLoading ? null : _signInWithGoogle,
                            ),
                          ),
                          SizedBox(width: size.width * 0.03),
                          Expanded(
                            child: _SocialButton(
                              svgAsset: 'assets/icons/facebook_logo.svg',
                              label: 'Facebook',
                              onTap: _isLoading ? null : _signInWithFacebook,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.03),

                      // Terms note
                      Text(
                        'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: size.width * 0.027,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AhorraColors.teal),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Feature Pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.02),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: w * 0.038),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: w * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome Button ───────────────────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: double.infinity,
      height: w * 0.138,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: borderColor != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor!),
                  )
                : null,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w600,
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

// ─── Social Button ────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String svgAsset;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.svgAsset,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: w * 0.128,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(svgAsset, width: w * 0.055, height: w * 0.055),
              SizedBox(width: w * 0.025),
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.037,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
