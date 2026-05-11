// lib/models.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Wallet Type ──────────────────────────────────────────────────────────────

enum WalletType { savings, cash, credit, investment, check }

extension WalletTypeExt on WalletType {
  String get label {
    switch (this) {
      case WalletType.savings:
        return 'Savings';
      case WalletType.cash:
        return 'Cash';
      case WalletType.credit:
        return 'Credit';
      case WalletType.investment:
        return 'Investment';
      case WalletType.check:
        return 'Check';
    }
  }

  // ─── Material icon for each wallet type ─────────────────────────────────
  IconData get iconData {
    switch (this) {
      case WalletType.savings:
        return Icons.savings_outlined;
      case WalletType.cash:
        return Icons.money;
      case WalletType.credit:
        return Icons.credit_card;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.check:
        return Icons.check_circle_outline;
    }
  }

  // Keep the old emoji getter for backward compatibility if needed, but remove later
  // String get icon => ...   (no longer used)

  String get key => name;

  static WalletType fromKey(String key) => WalletType.values
      .firstWhere((e) => e.name == key, orElse: () => WalletType.savings);
}

// ─── Wallet ───────────────────────────────────────────────────────────────────

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  double balance;

  Wallet({
    String? id,
    required this.name,
    required this.type,
    this.balance = 0.0,
  }) : id = id ?? _uuid.v4();

  Wallet copyWith({String? name, WalletType? type, double? balance}) => Wallet(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.key,
        'balance': balance,
      };

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        id: j['id'] as String,
        name: j['name'] as String,
        type: WalletTypeExt.fromKey(j['type'] as String),
        balance: (j['balance'] as num).toDouble(),
      );
}

// ─── Transaction ──────────────────────────────────────────────────────────────

class Transaction {
  final String id;
  final String walletId;
  final String walletName;
  final String category;
  final String description;
  final double amount;
  final bool isExpense;
  final DateTime date;

  Transaction({
    String? id,
    required this.walletId,
    required this.walletName,
    required this.category,
    this.description = '',
    required this.amount,
    required this.isExpense,
    DateTime? date,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'walletName': walletName,
        'category': category,
        'description': description,
        'amount': amount,
        'isExpense': isExpense,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        walletId: j['walletId'] as String,
        walletName: j['walletName'] as String,
        category: j['category'] as String,
        description: j['description'] as String? ?? '',
        amount: (j['amount'] as num).toDouble(),
        isExpense: j['isExpense'] as bool,
        date: DateTime.parse(j['date'] as String),
      );
}

// ─── Budget Period ────────────────────────────────────────────────────────────

enum BudgetPeriod { monthly, weekly }

extension BudgetPeriodExt on BudgetPeriod {
  String get label => this == BudgetPeriod.monthly ? 'Monthly' : 'Weekly';
  String get key => name;
  static BudgetPeriod fromKey(String key) => BudgetPeriod.values
      .firstWhere((e) => e.name == key, orElse: () => BudgetPeriod.monthly);
}

// ─── Budget ───────────────────────────────────────────────────────────────────

class Budget {
  final String id;
  final String category;
  final double limit;
  final BudgetPeriod period;

  Budget({
    String? id,
    required this.category,
    required this.limit,
    required this.period,
  }) : id = id ?? _uuid.v4();

  Budget copyWith({String? category, double? limit, BudgetPeriod? period}) =>
      Budget(
        id: id,
        category: category ?? this.category,
        limit: limit ?? this.limit,
        period: period ?? this.period,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
        'period': period.key,
      };

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
        id: j['id'] as String,
        category: j['category'] as String,
        limit: (j['limit'] as num).toDouble(),
        period: BudgetPeriodExt.fromKey(j['period'] as String),
      );
}

// ─── Analytics Data ──────────────────────────────────────────────────────

class MonthlyData {
  final int month;
  final int year;
  final double income;
  final double expense;
  final double savings;

  MonthlyData({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.savings,
  });

  String get monthName {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(month - 1) % 12];
  }
}

class CategorySpending {
  final String category;
  final double amount;
  CategorySpending({required this.category, required this.amount});
}

class UnusualSpending {
  final String category;
  final double amount;
  final double expectedAmount;
  final double deviation;
  UnusualSpending({
    required this.category,
    required this.amount,
    required this.expectedAmount,
    required this.deviation,
  });
}
