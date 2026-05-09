// lib/terms_screen.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';
import 'signup_screen.dart';

class TermsModal extends StatelessWidget {
  const TermsModal({super.key});

  static const String _termsText =
      'Welcome to Ahorra. By using this app you agree to the following terms.\n\n'
      '1. Privacy\nWe respect your privacy. Data you enter (expenses, income) is stored locally on your device and used only to improve your experience. We do not share personal information without your consent, except as required by law.\n\n'
      '2. Limitations\nAhorra provides financial tracking tools but does not offer professional financial, legal, or investment advice. All decisions you make based on the app are your responsibility.\n\n'
      '3. Service Availability\nWe aim to keep the app running smoothly, but cannot guarantee uninterrupted access. We are not liable for any losses from downtime or data loss.\n\n'
      '4. Changes to Terms\nWe may update these terms from time to time. Continued use after changes means you accept the updated terms.\n\n'
      '5. Contact\nIf you have questions, please contact us through the app\'s support section.';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.width * 0.05)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.055),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            SizedBox(
              height: size.height * 0.38,
              child: SingleChildScrollView(
                child: Text(
                  _termsText,
                  style: TextStyle(
                    fontSize: size.width * 0.033,
                    color: const Color(0xFF333333),
                    height: 1.65,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.025),
            SizedBox(
              width: double.infinity,
              height: size.width * 0.135,
              child: Material(
                color: AhorraColors.teal,
                borderRadius: BorderRadius.circular(size.width * 0.035),
                child: InkWell(
                  borderRadius: BorderRadius.circular(size.width * 0.035),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: Center(
                    child: Text(
                      'Accept and Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
