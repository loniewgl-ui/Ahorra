// lib/utils/data_export_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'analytics_helper.dart';
import 'app_data.dart'; // ← use the real AppData class

class DataExportHelper {
  static Future<String> exportToJson(
    List<Wallet> wallets,
    List<Transaction> transactions,
    List<Budget> budgets,
  ) async {
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }

  static Future<String> exportToCsv(List<Transaction> transactions) async {
    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Description,Wallet,Amount,Type');
    for (final t in transactions) {
      buffer.writeln('${t.date.toIso8601String()},'
          '${t.category},'
          '"${t.description.replaceAll('"', '""')}",'
          '${t.walletName},'
          '${t.amount},'
          '${t.isExpense ? "Expense" : "Income"}');
    }
    return buffer.toString();
  }

  static Future<String> generateReport(AppData appData) async {
    final now = DateTime.now();
    final thisMonth = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );

    final monthlyTrend =
        AnalyticsHelper.getMonthlyTrend(appData.transactions, 3);
    final topCategories =
        AnalyticsHelper.getTopSpendingCategories(appData.transactions, 5);
    final savingsRate =
        AnalyticsHelper.getSavingsRate(appData.transactions, thisMonth);

    final report = '''
═══════════════════════════════════════
          AHORRA FINANCIAL REPORT
          Generated: ${now.toLocal()}
═══════════════════════════════════════

📊 SUMMARY
───────────────────────────────────────
Total Net Worth: ₱${appData.totalNetWorth.toStringAsFixed(2)}
Total Wallets: ${appData.wallets.length}
Total Transactions: ${appData.transactions.length}
Active Budgets: ${appData.budgets.length}

💰 THIS MONTH
───────────────────────────────────────
Income: ₱${appData.thisMonthIncome.toStringAsFixed(2)}
Expenses: ₱${appData.thisMonthExpense.toStringAsFixed(2)}
Net Savings: ₱${(appData.thisMonthIncome - appData.thisMonthExpense).toStringAsFixed(2)}
Savings Rate: ${savingsRate.toStringAsFixed(1)}%

📈 TOP SPENDING CATEGORIES
───────────────────────────────────────
${topCategories.asMap().entries.map((e) => '${e.key + 1}. ${e.value.category}: ₱${e.value.amount.toStringAsFixed(2)}').join('\n')}

📉 MONTHLY TREND (Last 3 months)
───────────────────────────────────────
${monthlyTrend.map((m) => '${m.monthName} ${m.year}: Income ₱${m.income.toStringAsFixed(0)} | Expenses ₱${m.expense.toStringAsFixed(0)} | Saved ${(m.income > 0 ? (m.savings / m.income) * 100 : 0).toStringAsFixed(1)}%').join('\n')}

💳 WALLET BREAKDOWN
───────────────────────────────────────
${appData.wallets.map((w) => '• ${w.name}: ₱${w.balance.toStringAsFixed(2)} (${w.type.label})').join('\n')}

═══════════════════════════════════════
    ''';
    return report;
  }

  static Future<void> saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    // Create a dedicated 'Ahorra Exports' folder
    final exportDir = Directory('${directory.path}/Ahorra Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$filename');
    await file.writeAsString(content);
  }
}
