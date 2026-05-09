// lib/signup_screen.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';
import '../widgets/ahorra_widgets.dart';
import 'terms_screen.dart';
import '../widgets/main_nav.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _acceptedTerms &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the terms and conditions.')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNav()),
      (route) => false,
    );
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: size.width * 0.07,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      'Join Ahorra Today',
                      style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: AhorraColors.textMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.035),
              const AhorraFormLabel('First Name'),
              AhorraInputField(
                hint: 'Enter first name',
                controller: _firstNameController,
              ),
              SizedBox(height: size.height * 0.018),
              const AhorraFormLabel('Last Name'),
              AhorraInputField(
                hint: 'Enter last name',
                controller: _lastNameController,
              ),
              SizedBox(height: size.height * 0.018),
              const AhorraFormLabel('Email'),
              AhorraInputField(
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              SizedBox(height: size.height * 0.018),
              const AhorraFormLabel('Password'),
              AhorraInputField(
                hint: 'Create a password',
                obscure: true,
                controller: _passwordController,
              ),
              SizedBox(height: size.height * 0.018),
              const AhorraFormLabel('Confirm Password'),
              AhorraInputField(
                hint: 'Confirm your password',
                obscure: true,
                controller: _confirmPasswordController,
              ),
              SizedBox(height: size.height * 0.025),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _acceptedTerms = !_acceptedTerms),
                    child: Container(
                      width: size.width * 0.055,
                      height: size.width * 0.055,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _acceptedTerms
                              ? AhorraColors.teal
                              : AhorraColors.checkboxBorder,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(size.width * 0.01),
                        color: _acceptedTerms
                            ? AhorraColors.teal
                            : Colors.transparent,
                      ),
                      child: _acceptedTerms
                          ? Icon(Icons.check,
                              size: size.width * 0.038, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(width: size.width * 0.025),
                  Text(
                    'I accept the ',
                    style: TextStyle(
                        fontSize: size.width * 0.033,
                        color: const Color(0xFF333333)),
                  ),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const TermsModal(),
                    ),
                    child: Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        fontSize: size.width * 0.033,
                        color: AhorraColors.linkTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.03),
              AhorraPrimaryButton(
                label: 'Create Account',
                backgroundColor: AhorraColors.teal,
                textColor: AhorraColors.textWhite,
                isLoading: _isSubmitting,
                onTap: _canSubmit ? () => _submit(context) : null,
              ),
              SizedBox(height: size.height * 0.025),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                        fontSize: size.width * 0.034,
                        color: const Color(0xFF555555)),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: size.width * 0.034,
                              color: AhorraColors.linkTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
