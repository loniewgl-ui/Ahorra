// lib/utils/test_data_generator.dart
import 'dart:math';
import '../models/models.dart';

class TestDataGenerator {
  static final Random _random = Random();

  static const List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Utilities',
    'Rent / Housing',
    'Education'
  ];

  static const List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment Return',
    'Other'
  ];

  static const List<String> _foodItems = [
    'Lunch',
    'Dinner',
    'Coffee',
    'Groceries',
    'Restaurant',
    'Takeout'
  ];

  static const List<String> _transportItems = [
    'Gas',
    'Bus Fare',
    'Taxi',
    'Subway',
    'Car Maintenance',
    'Parking'
  ];

  static const List<String> _shoppingItems = [
    'Clothes',
    'Electronics',
    'Home Goods',
    'Books',
    'Gifts',
    'Supplies'
  ];

  static const List<String> _entertainmentItems = [
    'Movies',
    'Concert',
    'Games',
    'Netflix',
    'Spotify',
    'Event Tickets'
  ];

  static const List<String> _healthcareItems = [
    'Doctor Visit',
    'Pharmacy',
    'Dental',
    'Insurance',
    'Gym',
    'Vitamins'
  ];

  static List<Wallet> generateWallets(int count) {
    final wallets = <Wallet>[];
    const types = [
      WalletType.savings,
      WalletType.cash,
      WalletType.credit,
      WalletType.investment,
      WalletType.check
    ];
    const names = [
      'Main Wallet',
      'Savings Account',
      'Cash',
      'Investment Fund',
      'Checking Account'
    ];

    for (int i = 0; i < count && i < types.length; i++) {
      wallets.add(Wallet(
        name: names[i],
        type: types[i],
        balance: 5000.0 + _random.nextInt(20000),
      ));
    }
    // If count > types.length, add generic wallets
    for (int i = types.length; i < count; i++) {
      wallets.add(Wallet(
        name: 'Wallet ${i + 1}',
        type: WalletType.cash,
        balance: 5000.0 + _random.nextInt(20000),
      ));
    }
    return wallets;
  }

  static List<Transaction> generateTransactions(
    List<Wallet> wallets,
    int count,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (wallets.isEmpty) return [];
    final transactions = <Transaction>[];
    final days = endDate.difference(startDate).inDays;

    for (int i = 0; i < count; i++) {
      final wallet = wallets[_random.nextInt(wallets.length)];
      final isExpense = _random.nextDouble() < 0.7;

      String category;
      String description;
      double amount;

      if (isExpense) {
        category =
            _expenseCategories[_random.nextInt(_expenseCategories.length)];
        description = _getExpenseDescription(category);
        amount = 5.0 + _random.nextInt(500);
      } else {
        category = _incomeCategories[_random.nextInt(_incomeCategories.length)];
        description = _getIncomeDescription(category);
        amount = 500.0 + _random.nextInt(5000);
      }

      final daysOffset = days > 0 ? _random.nextInt(days + 1) : 0;
      final date = startDate.add(Duration(days: daysOffset));

      transactions.add(Transaction(
        walletId: wallet.id,
        walletName: wallet.name,
        category: category,
        description: description,
        amount: amount.toDouble(),
        isExpense: isExpense,
        date: DateTime(date.year, date.month, date.day, _random.nextInt(23),
            _random.nextInt(59)),
      ));
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  static String _getExpenseDescription(String category) {
    switch (category) {
      case 'Food & Dining':
        return _foodItems[_random.nextInt(_foodItems.length)];
      case 'Transportation':
        return _transportItems[_random.nextInt(_transportItems.length)];
      case 'Shopping':
        return _shoppingItems[_random.nextInt(_shoppingItems.length)];
      case 'Entertainment':
        return _entertainmentItems[_random.nextInt(_entertainmentItems.length)];
      case 'Healthcare':
        return _healthcareItems[_random.nextInt(_healthcareItems.length)];
      default:
        return '${category} expense';
    }
  }

  static String _getIncomeDescription(String category) {
    switch (category) {
      case 'Salary':
        return 'Monthly Salary';
      case 'Freelance':
        return 'Freelance Project';
      case 'Investment Return':
        return 'Dividend / Interest';
      default:
        return 'Income received';
    }
  }

  static List<Budget> generateBudgets(List<Transaction> transactions) {
    final categorySpending = <String, double>{};

    for (final t in transactions.where((t) => t.isExpense)) {
      categorySpending.update(t.category, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }

    final budgets = <Budget>[];
    for (final entry in categorySpending.entries) {
      if (entry.value > 100) {
        final limit = entry.value * (0.8 + _random.nextDouble() * 0.4);
        budgets.add(Budget(
          category: entry.key,
          limit: limit,
          period:
              _random.nextBool() ? BudgetPeriod.monthly : BudgetPeriod.weekly,
        ));
      }
    }
    return budgets;
  }
}
