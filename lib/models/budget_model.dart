// lib/models/budget_model.dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
  final int month;
  final int year;

  Budget({
    String? id,
    required this.category,
    required this.limit,
    required this.period,
    int? month,
    int? year,
  })  : id = id ?? _uuid.v4(),
        month = month ?? DateTime.now().month,
        year = year ?? DateTime.now().year;

  DateTime get periodStart {
    if (period == BudgetPeriod.monthly) {
      return DateTime(year, month, 1);
    }
    final firstDay = DateTime(year, month, 1);
    final daysUntilMonday = (DateTime.monday - firstDay.weekday + 7) % 7;
    return firstDay.add(Duration(days: daysUntilMonday));
  }

  DateTime get periodEnd {
    if (period == BudgetPeriod.monthly) {
      if (month == 12) {
        return DateTime(year + 1, 1, 1);
      }
      return DateTime(year, month + 1, 1);
    }
    return periodStart.add(const Duration(days: 7));
  }

  String get periodLabel {
    if (period == BudgetPeriod.monthly) {
      return '${_months[month - 1]} $year';
    }
    final start = periodStart;
    return '${start.month}/${start.day}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Budget copyWith({
    String? category,
    double? limit,
    BudgetPeriod? period,
    int? month,
    int? year,
  }) =>
      Budget(
        id: id,
        category: category ?? this.category,
        limit: limit ?? this.limit,
        period: period ?? this.period,
        month: month ?? this.month,
        year: year ?? this.year,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
        'period': period.key,
        'month': month,
        'year': year,
      };

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
        id: j['id'] as String,
        category: j['category'] as String,
        limit: (j['limit'] as num).toDouble(),
        period: BudgetPeriodExt.fromKey(j['period'] as String),
        month: j['month'] as int? ?? DateTime.now().month,
        year: j['year'] as int? ?? DateTime.now().year,
      );
}
