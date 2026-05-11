import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';

class TermsModal extends StatelessWidget {
  final VoidCallback? onAccept;

  const TermsModal({super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please review the terms and conditions before you continue. By accepting, you agree to our app policies and privacy terms.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: const Text(
                  '1. Use this app responsibly and keep your account secure.\n\n'
                  '2. Your data is stored securely, but always safeguard your login credentials.\n\n'
                  '3. You may not use this app for unlawful purposes.\n\n'
                  '4. We may update the terms at any time, and continued use means acceptance of those updates.\n\n'
                  '5. If you have questions, contact support through the app.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AhorraColors.teal, // <-- teal
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onAccept?.call();
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AhorraColors.teal,
                        side: BorderSide(color: AhorraColors.teal),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
