// lib/app_data.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppData extends ChangeNotifier {
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  bool _loaded = false;

  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get isLoaded => _loaded;

  // ── Computed ──────────────────────────────────────────────────────────────

  double get totalNetWorth => _wallets.fold(0.0, (s, w) => s + w.balance);

  double get thisMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            !t.isExpense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.isExpense && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double thisWeekExpense() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _transactions
        .where((t) => t.isExpense && !t.date.isBefore(weekStart))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double spentForBudget(Budget b) {
    final now = DateTime.now();
    return _transactions.where((t) {
      if (!t.isExpense) return false;
      if (t.category.toLowerCase() != b.category.toLowerCase()) return false;
      if (b.period == BudgetPeriod.monthly) {
        return t.date.year == now.year && t.date.month == now.month;
      } else {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return !t.date.isBefore(weekStart);
      }
    }).fold(0.0, (s, t) => s + t.amount);
  }

  // ── Load / Save ───────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final walletsJson = prefs.getString('wallets');
      if (walletsJson != null) {
        final List<dynamic> list = jsonDecode(walletsJson);
        _wallets = list
            .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final txnsJson = prefs.getString('transactions');
      if (txnsJson != null) {
        final List<dynamic> list = jsonDecode(txnsJson);
        _transactions = list
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList();
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
      final budgetsJson = prefs.getString('budgets');
      if (budgetsJson != null) {
        final List<dynamic> list = jsonDecode(budgetsJson);
        _budgets = list
            .map((e) => Budget.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'wallets', jsonEncode(_wallets.map((w) => w.toJson()).toList()));
    await prefs.setString('transactions',
        jsonEncode(_transactions.map((t) => t.toJson()).toList()));
    await prefs.setString(
        'budgets', jsonEncode(_budgets.map((b) => b.toJson()).toList()));
  }

  // ── Wallets ───────────────────────────────────────────────────────────────

  void addWallet(Wallet wallet) {
    _wallets.add(wallet);
    notifyListeners();
    _save();
  }

  void deleteWallet(String walletId) {
    _wallets.removeWhere((w) => w.id == walletId);
    _transactions.removeWhere((t) => t.walletId == walletId);
    notifyListeners();
    _save();
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  void addTransaction(Transaction txn) {
    // Update wallet balance
    final idx = _wallets.indexWhere((w) => w.id == txn.walletId);
    if (idx != -1) {
      _wallets[idx].balance += txn.isExpense ? -txn.amount : txn.amount;
    }
    _transactions.insert(0, txn);
    notifyListeners();
    _save();
  }

  void deleteTransaction(String txnId) {
    final txn = _transactions.firstWhere((t) => t.id == txnId,
        orElse: () => throw StateError('not found'));
    final idx = _wallets.indexWhere((w) => w.id == txn.walletId);
    if (idx != -1) {
      _wallets[idx].balance += txn.isExpense ? txn.amount : -txn.amount;
    }
    _transactions.removeWhere((t) => t.id == txnId);
    notifyListeners();
    _save();
  }

  // ── Budgets ───────────────────────────────────────────────────────────────

  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
    _save();
  }

  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
    _save();
  }

  // ── Clear All (sign-out) ──────────────────────────────────────────────────

  Future<void> clearAll() async {
    _wallets = [];
    _transactions = [];
    _budgets = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
