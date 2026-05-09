// lib/welcome_screen.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';
import '../widgets/ahorra_widgets.dart';
import 'terms_screen.dart';
import '../widgets/main_nav.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showTerms(BuildContext context) {
    showDialog(context: context, builder: (_) => const TermsModal());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final double hPad = size.width * 0.065;
    final double sectionGap = size.height * 0.022;
    final double topInset = media.padding.top;

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
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalHeight = constraints.maxHeight;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: totalHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: (topInset * 0.45) + (totalHeight * 0.035)),
                        const AhorraWalletIcon(),
                        SizedBox(height: sectionGap),
                        Text(
                          'WELCOME TO',
                          style: TextStyle(
                            color: AhorraColors.textLight,
                            fontSize: size.width * 0.035,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: size.height * 0.005),
                        Text(
                          'Ahorra',
                          style: TextStyle(
                            color: AhorraColors.textWhite,
                            fontSize: size.width * 0.13,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: sectionGap * 0.9),
                        Text(
                          'Your complete personal finance companion. Track expenses, manage multiple wallets, set budgets, and gain insights into your spending.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AhorraColors.textMuted,
                            fontSize: size.width * 0.035,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: sectionGap * 2.1),
                        AhorraPrimaryButton(
                          label: 'Get Started',
                          backgroundColor: AhorraColors.getStartedBg,
                          textColor: const Color(0xFF1A3A38),
                          onTap: () => _showTerms(context),
                        ),
                        SizedBox(height: sectionGap * 0.6),
                        AhorraPrimaryButton(
                          label: 'Sign In',
                          backgroundColor: AhorraColors.teal,
                          textColor: AhorraColors.textWhite,
                          onTap: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const MainNav()),
                              (route) => false,
                            );
                          },
                        ),
                        SizedBox(height: sectionGap * 1.35),
                        const AhorraFeatureGrid(),
                        SizedBox(height: sectionGap),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
