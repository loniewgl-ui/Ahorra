// lib/models/analytics_model.dart

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
