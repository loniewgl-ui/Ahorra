// lib/models/wallet_model.dart
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

  String get key => name;

  static WalletType fromKey(String key) => WalletType.values
      .firstWhere((e) => e.name == key, orElse: () => WalletType.savings);
}

// ─── Wallet ───────────────────────────────────────────────────────────────────

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final double balance;

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
