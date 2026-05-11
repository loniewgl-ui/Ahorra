// lib/data_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_data.dart';
import '../utils/test_data_generator.dart'; // uses the generator you already have

class DataDebugScreen extends StatelessWidget {
  const DataDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Analytics & Testing'),
        backgroundColor: const Color(0xFF2A6460),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_chart),
          label: const Text('Generate Test Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A6460),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          onPressed: () async {
            final appData = context.read<AppData>();

            // 1. Generate wallets (3 wallets)
            final wallets = TestDataGenerator.generateWallets(3);

            // 2. Generate transactions for the past 30 days
            final startDate = DateTime.now().subtract(const Duration(days: 30));
            final endDate = DateTime.now();
            final transactions = TestDataGenerator.generateTransactions(
                wallets, 20, startDate, endDate);

            // 3. Generate budgets based on those transactions
            final budgets = TestDataGenerator.generateBudgets(transactions);

            // 4. Add everything to AppData (this also triggers Firestore saves)
            for (final w in wallets) {
              appData.addWallet(w);
            }
            for (final t in transactions) {
              appData.addTransaction(t);
            }
            for (final b in budgets) {
              appData.addBudget(b);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test data generated! Check your home screen.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
