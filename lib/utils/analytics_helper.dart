// lib/utils/analytics_helper.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';

class AnalyticsHelper {
  static Map<String, double> getSpendingByCategory(
      List<Transaction> transactions, DateTimeRange range) {
    final filtered = transactions.where((t) =>
        t.isExpense &&
        !t.date.isBefore(range.start) &&
        !t.date.isAfter(range.end));
    final result = <String, double>{};
    for (final t in filtered) {
      result.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return result;
  }

  static Map<String, double> getIncomeBySource(
      List<Transaction> transactions, DateTimeRange range) {
    final filtered = transactions.where((t) =>
        !t.isExpense &&
        !t.date.isBefore(range.start) &&
        !t.date.isAfter(range.end));
    final result = <String, double>{};
    for (final t in filtered) {
      result.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return result;
  }

  static double getDailyAverageSpending(
      List<Transaction> transactions, DateTimeRange range) {
    final days = range.end.difference(range.start).inDays + 1;
    final totalSpending = transactions
        .where((t) =>
            t.isExpense &&
            !t.date.isBefore(range.start) &&
            !t.date.isAfter(range.end))
        .fold(0.0, (s, t) => s + t.amount);
    return days > 0 ? totalSpending / days : 0.0;
  }

  static double getSavingsRate(
      List<Transaction> transactions, DateTimeRange range) {
    final filtered = transactions.where(
        (t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end));
    final income =
        filtered.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final expense =
        filtered.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    return income > 0 ? ((income - expense) / income) * 100 : 0.0;
  }

  static List<MonthlyData> getMonthlyTrend(
      List<Transaction> transactions, int months) {
    final now = DateTime.now();
    final result = <MonthlyData>[];

    for (int i = months - 1; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year;
      int adjustedMonth = month;
      int adjustedYear = year;
      if (month <= 0) {
        adjustedMonth = month + 12;
        adjustedYear = year - 1;
      }

      final range = DateTimeRange(
        start: DateTime(adjustedYear, adjustedMonth, 1),
        end: DateTime(adjustedYear, adjustedMonth + 1, 0, 23, 59, 59),
      );

      final monthTx = transactions.where(
          (t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end));

      final income =
          monthTx.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final expense =
          monthTx.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

      result.add(MonthlyData(
        month: adjustedMonth,
        year: adjustedYear,
        income: income,
        expense: expense,
        savings: income - expense,
      ));
    }
    return result;
  }

  static List<CategorySpending> getTopSpendingCategories(
      List<Transaction> transactions, int limit) {
    final spending = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      spending.update(t.category, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(limit);
    return top
        .map((e) => CategorySpending(category: e.key, amount: e.value))
        .toList();
  }

  static List<WalletUtilization> getWalletUtilization(
      List<Wallet> wallets, List<Transaction> transactions) {
    final totalSpending = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    if (totalSpending == 0) {
      return wallets
          .map((w) => WalletUtilization(wallet: w, spending: 0, percentage: 0))
          .toList();
    }
    return wallets.map((wallet) {
      final walletSpending = transactions
          .where((t) => t.isExpense && t.walletId == wallet.id)
          .fold(0.0, (s, t) => s + t.amount);
      final percentage = (walletSpending / totalSpending) * 100;
      return WalletUtilization(
          wallet: wallet, spending: walletSpending, percentage: percentage);
    }).toList();
  }

  static double predictNextMonthSpending(List<Transaction> transactions) {
    final now = DateTime.now();
    final List<double> monthlyTotals = [];
    for (int i = 1; i <= 3; i++) {
      final month = now.month - i;
      int adjustedMonth = month;
      int adjustedYear = now.year;
      if (month <= 0) {
        adjustedMonth = month + 12;
        adjustedYear = now.year - 1;
      }
      final range = DateTimeRange(
        start: DateTime(adjustedYear, adjustedMonth, 1),
        end: DateTime(adjustedYear, adjustedMonth + 1, 0, 23, 59, 59),
      );
      final total = transactions
          .where((t) =>
              t.isExpense &&
              !t.date.isBefore(range.start) &&
              !t.date.isAfter(range.end))
          .fold(0.0, (s, t) => s + t.amount);
      if (total > 0) monthlyTotals.add(total);
    }
    if (monthlyTotals.isEmpty) return 0.0;
    return monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  static List<UnusualSpending> findUnusualSpending(
      List<Transaction> transactions) {
    const threshold = 2.0;
    final unusual = <UnusualSpending>[];
    final categoryAmounts = <String, List<double>>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      categoryAmounts.putIfAbsent(t.category, () => []).add(t.amount);
    }
    for (final entry in categoryAmounts.entries) {
      final amounts = entry.value;
      if (amounts.length < 3) continue;
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) /
              amounts.length;
      final stdDev = sqrt(variance);
      for (final amount in amounts) {
        if (amount > mean + threshold * stdDev) {
          unusual.add(UnusualSpending(
            category: entry.key,
            amount: amount,
            expectedAmount: mean,
            deviation: (amount - mean) / mean * 100,
          ));
        }
      }
    }
    return unusual;
  }
}

class WalletUtilization {
  final Wallet wallet;
  final double spending;
  final double percentage;
  WalletUtilization(
      {required this.wallet, required this.spending, required this.percentage});
}
