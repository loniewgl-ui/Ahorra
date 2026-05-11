// lib/utils/app_data.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../models/models.dart';
import 'notification_service.dart';

class AppData extends ChangeNotifier {
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  bool _loaded = false;

  Timer? _saveDebounce;

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
      if (t.category.trim().toLowerCase() != b.category.trim().toLowerCase())
        return false;
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
    _loaded = false;
    _wallets = [];
    _transactions = [];
    _budgets = [];

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadFromFirestore(user.uid);
    } else {
      print('ℹ️ No user logged in, data not loaded from Firestore');
    }

    _loaded = true;
    notifyListeners();
  }

  Future<bool> _loadFromFirestore(String uid) async {
    try {
      final doc = await fs.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;

      final walletsData = data['wallets'] as List<dynamic>?;
      final transactionsData = data['transactions'] as List<dynamic>?;
      final budgetsData = data['budgets'] as List<dynamic>?;

      _wallets = walletsData != null
          ? walletsData
              .map((e) => Wallet.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [];

      _transactions = transactionsData != null
          ? transactionsData
              .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [];
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _budgets = budgetsData != null
          ? budgetsData
              .map((e) => Budget.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [];

      return true;
    } catch (e) {
      print('❌ Error loading data from Firestore: $e');
      return false;
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('📦 Starting save for user: ${user.uid}');
        await _saveToFirestore(user.uid);
      } else {
        print('⚠️ Save skipped - no authenticated user');
      }
    });
  }

  Future<void> _saveToFirestore(String uid) async {
    try {
      await fs.FirebaseFirestore.instance.collection('users').doc(uid).set({
        'wallets': _wallets.map((w) => w.toJson()).toList(),
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'budgets': _budgets.map((b) => b.toJson()).toList(),
        'lastDataUpdate': fs.FieldValue.serverTimestamp(),
      }, fs.SetOptions(merge: true));
      print('✅ Firestore data saved successfully');
    } catch (e) {
      print('❌ Firestore save FAILED: $e');
    }
  }

  // ── Wallets ───────────────────────────────────────────────────────────────
  void addWallet(Wallet wallet) {
    _wallets.add(wallet);
    notifyListeners();
    _scheduleSave();
  }

  void deleteWallet(String walletId) {
    _wallets.removeWhere((w) => w.id == walletId);
    _transactions.removeWhere((t) => t.walletId == walletId);
    notifyListeners();
    _scheduleSave();
  }

  // ── Transactions (NOW WITH UNIVERSAL NOTIFICATION) ────────────────────────
  void addTransaction(Transaction txn) {
    final oldNetWorth = totalNetWorth;
    final idx = _wallets.indexWhere((w) => w.id == txn.walletId);
    if (idx != -1) {
      _wallets[idx].balance += txn.isExpense ? -txn.amount : txn.amount;
    }
    _transactions.insert(0, txn);
    notifyListeners();
    _scheduleSave();

    // ---- UNIVERSAL TRANSACTION NOTIFICATION ----
    final type = txn.isExpense ? 'Expense' : 'Income';
    final body = '${type}: ₱${txn.amount.toStringAsFixed(2)} – ${txn.category}';
    NotificationService.show(title: 'Transaction Added', body: body);
    _saveNotification('Transaction Added', body, false);

    // ---- BUDGET OVERSPEND NOTIFICATION ----
    if (txn.isExpense) {
      _checkBudgetOverspend(txn);
    }
    _checkNetWorthOverspend(oldNetWorth);
  }

  void _checkBudgetOverspend(Transaction txn) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) return;

    for (final budget in _budgets) {
      if (budget.category.trim().toLowerCase() !=
          txn.category.trim().toLowerCase()) continue;
      final spent = spentForBudget(budget);
      if (spent > budget.limit && (spent - txn.amount) <= budget.limit) {
        final body =
            '${budget.category} overspent by ₱${(spent - budget.limit).toStringAsFixed(2)}';
        NotificationService.show(title: 'Budget Exceeded!', body: body);
        await _saveNotification('Budget Exceeded!', body, true);
      }
    }
  }

  void _checkNetWorthOverspend(double oldNetWorth) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) return;

    final newNetWorth = totalNetWorth;
    if (newNetWorth < 0 && oldNetWorth >= 0) {
      final body =
          'Your total net worth is now negative (₱${newNetWorth.toStringAsFixed(2)})';
      NotificationService.show(title: 'You\'re in debt!', body: body);
      await _saveNotification('You\'re in debt!', body, true);
    }
  }

  Future<void> _saveNotification(
      String title, String body, bool overspent) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('saved_notifications') ?? '[]';
    final list = json.decode(jsonString) as List<dynamic>;
    list.add({
      'title': title,
      'body': body,
      'overspent': overspent,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (list.length > 20) list.removeAt(0);
    await prefs.setString('saved_notifications', json.encode(list));
  }

  void deleteTransaction(String txnId) {
    try {
      final txn = _transactions.firstWhere((t) => t.id == txnId);
      final idx = _wallets.indexWhere((w) => w.id == txn.walletId);
      if (idx != -1) {
        _wallets[idx].balance += txn.isExpense ? txn.amount : -txn.amount;
      }
      _transactions.removeWhere((t) => t.id == txnId);
      notifyListeners();
      _scheduleSave();
    } catch (e) {
      print('❌ Transaction not found: $e');
    }
  }

  // ── Budgets ───────────────────────────────────────────────────────────────
  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
    _scheduleSave();
  }

  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
    _scheduleSave();
  }

  // ── Delete user data ──────────────────────────────────────────────────────
  Future<void> deleteUserData() async {
    _saveDebounce?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await fs.FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        print('✅ Firestore data deleted');
      } catch (e) {
        print('❌ Failed to delete Firestore data: $e');
        rethrow;
      }
    }

    _wallets = [];
    _transactions = [];
    _budgets = [];
    _loaded = false;

    final prefs = await SharedPreferences.getInstance();
    final pinKey = 'pin_${user?.uid ?? ''}';
    final savedPin = prefs.getString(pinKey);
    await prefs.clear();
    if (savedPin != null && user != null) {
      await prefs.setString(pinKey, savedPin);
    }

    notifyListeners();
  }

  Future<void> clearAll() async {
    _saveDebounce?.cancel();
    _wallets = [];
    _transactions = [];
    _budgets = [];
    _loaded = false;

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? savedPin;
    if (uid != null) {
      savedPin = prefs.getString('pin_$uid');
    }

    await prefs.clear();
    if (uid != null && savedPin != null) {
      await prefs.setString('pin_$uid', savedPin);
    }

    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
