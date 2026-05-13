import 'package:flutter/material.dart';
import '../../utils/ahorra_colors.dart';

class TermsModal extends StatelessWidget {
  final VoidCallback? onAccept;

  const TermsModal({super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Last updated: March 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please read these terms carefully before using the Ahorra application. By creating an account or using the app, you agree to be bound by these terms.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF555555)),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            const Divider(height: 1),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      number: '1.',
                      title: 'Acceptance of Terms',
                      body:
                          'By accessing or using Ahorra ("the App"), you agree to be legally bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use the App. We reserve the right to update these terms at any time, and continued use constitutes acceptance of the revised terms.',
                    ),
                    _Section(
                      number: '2.',
                      title: 'Description of Service',
                      body:
                          'Ahorra is a personal financial management tool designed to help you track expenses, manage budgets, monitor wallets, and analyze spending patterns. The App provides data storage, categorization, and visualization features. Ahorra is not a financial institution, does not provide financial advice, and does not process payments or hold funds on your behalf.',
                    ),
                    _Section(
                      number: '3.',
                      title: 'User Accounts & Security',
                      body:
                          'You are responsible for maintaining the confidentiality of your login credentials and PIN. You must notify us immediately of any unauthorized use of your account. You are solely responsible for all activity that occurs under your account. You must be at least 13 years of age to use this App.',
                    ),
                    _Section(
                      number: '4.',
                      title: 'Data Storage & Privacy',
                      body:
                          'Your financial data is stored securely using Firebase (Google Cloud Platform). We use industry-standard encryption for data transmission and storage. Your data is synced across your devices to provide a seamless experience. You retain full ownership of your data. We do not sell, share, or monetize your personal financial information. For complete details, refer to our Privacy Policy within the App.',
                    ),
                    _Section(
                      number: '5.',
                      title: 'User Responsibilities',
                      body:
                          'You agree to enter accurate financial information and not to use the App for any unlawful or fraudulent activity. You acknowledge that the accuracy of budget tracking, analytics, and reports depends on the correctness of the data you provide. We recommend regularly exporting or backing up your data.',
                    ),
                    _Section(
                      number: '6.',
                      title: 'Limitation of Liability',
                      body:
                          'Ahorra is provided "as is" without warranty of any kind. We shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use or inability to use the App, including but not limited to data loss, financial decisions made based on App analytics, or service interruptions. You use the App at your own risk.',
                    ),
                    _Section(
                      number: '7.',
                      title: 'Termination',
                      body:
                          'You may delete your account and associated data at any time through the Settings page. We reserve the right to suspend or terminate access to the App for violations of these terms. Upon termination, your data will be permanently deleted from our servers within a reasonable timeframe.',
                    ),
                    _Section(
                      number: '8.',
                      title: 'Contact',
                      body:
                          'For questions, support, or concerns regarding these terms, please contact us through the "Send Feedback" option in App Settings or email support@ahorra.app.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'By tapping "Accept", you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
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
                        backgroundColor: AhorraColors.teal,
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
                        side: const BorderSide(color: AhorraColors.teal),
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

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number $title',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
