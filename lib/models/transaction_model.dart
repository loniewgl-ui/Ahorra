// lib/models/transaction_model.dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
