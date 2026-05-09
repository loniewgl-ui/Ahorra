import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../models/models.dart';
import 'settings_screen.dart';

// ─── Analytics Screen ─────────────────────────────────────────────────────────

enum AnalyticsPeriod { week, month, year }

enum ChartType { bar, donut, line }

enum AnalyticsMetric { expense, income, net }

extension AnalyticsMetricLabel on AnalyticsMetric {
  String get label {
    switch (this) {
      case AnalyticsMetric.expense:
        return 'Expense';
      case AnalyticsMetric.income:
        return 'Income';
      case AnalyticsMetric.net:
        return 'Net';
    }
  }
}

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get shortLabel {
    switch (this) {
      case AnalyticsPeriod.week:
        return 'Weekly';
      case AnalyticsPeriod.month:
        return 'Monthly';
      case AnalyticsPeriod.year:
        return 'Yearly';
    }
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.week;
  ChartType _chartType = ChartType.bar;
  AnalyticsMetric _metric = AnalyticsMetric.expense;

  DateTimeRange _rangeFor(AnalyticsPeriod period, DateTime now) {
    if (period == AnalyticsPeriod.week) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
        start: start,
        end: start
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
      );
    }
    if (period == AnalyticsPeriod.month) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    }
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _previousRangeFor(
      AnalyticsPeriod period, DateTimeRange current) {
    if (period == AnalyticsPeriod.week) {
      final start = current.start.subtract(const Duration(days: 7));
      return DateTimeRange(
        start: start,
        end: start
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
      );
    }
    if (period == AnalyticsPeriod.month) {
      final prevMonthDate =
          DateTime(current.start.year, current.start.month - 1, 1);
      return DateTimeRange(
        start: prevMonthDate,
        end: DateTime(
            prevMonthDate.year, prevMonthDate.month + 1, 0, 23, 59, 59),
      );
    }
    final prevYear = current.start.year - 1;
    return DateTimeRange(
      start: DateTime(prevYear, 1, 1),
      end: DateTime(prevYear, 12, 31, 23, 59, 59),
    );
  }

  List<Transaction> _txInRange(List<Transaction> all, DateTimeRange range) {
    return all
        .where(
            (t) => !t.date.isBefore(range.start) && !t.date.isAfter(range.end))
        .toList();
  }

  List<_DayData> _buildSeries(List<Transaction> txns, DateTime now) {
    double _signedValue(Transaction t) {
      if (_metric == AnalyticsMetric.expense) return t.isExpense ? t.amount : 0;
      if (_metric == AnalyticsMetric.income) return t.isExpense ? 0 : t.amount;
      return t.isExpense ? -t.amount : t.amount;
    }

    if (_period == AnalyticsPeriod.week) {
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final values = List<double>.filled(7, 0.0);
      for (final t in txns) {
        final idx = (t.date.weekday - 1).clamp(0, 6);
        values[idx] += _signedValue(t);
      }
      return List.generate(7, (i) => _DayData(labels[i], values[i]));
    }

    if (_period == AnalyticsPeriod.month) {
      final values = List<double>.filled(5, 0.0);
      for (final t in txns) {
        final idx = ((t.date.day - 1) ~/ 7).clamp(0, 4);
        values[idx] += _signedValue(t);
      }
      return List.generate(5, (i) => _DayData('Wk${i + 1}', values[i]));
    }

    final values = List<double>.filled(12, 0.0);
    for (final t in txns) {
      final idx = (t.date.month - 1).clamp(0, 11);
      values[idx] += _signedValue(t);
    }
    return List.generate(
      12,
      (i) => _DayData(
          intl.DateFormat('MMM').format(DateTime(now.year, i + 1)), values[i]),
    );
  }

  List<_DonutSlice> _buildCategorySlices(List<Transaction> txns) {
    if (_metric == AnalyticsMetric.net) {
      final income =
          txns.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
      final expense =
          txns.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
      final slices = <_DonutSlice>[];
      if (income > 0) {
        slices.add(_DonutSlice('Income', income, const Color(0xFF2E9E5B)));
      }
      if (expense > 0) {
        slices.add(_DonutSlice('Expense', expense, const Color(0xFFD94040)));
      }
      return slices;
    }

    final byCategory = <String, double>{};
    for (final t in txns.where(
      (e) => _metric == AnalyticsMetric.expense ? e.isExpense : !e.isExpense,
    )) {
      byCategory.update(t.category, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    const palette = [
      Color(0xFF4CAF50),
      Color(0xFF9C27B0),
      Color(0xFF2196F3),
      Color(0xFFFF5722),
      Color(0xFFFFC107),
      Color(0xFF00BCD4),
    ];
    return List.generate(
      top.length,
      (i) => _DonutSlice(top[i].key, top[i].value, palette[i % palette.length]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final allTx = data.transactions;
    final now = DateTime.now();
    final currentRange = _rangeFor(_period, now);
    final previousRange = _previousRangeFor(_period, currentRange);
    final currentTx = _txInRange(allTx, currentRange);
    final previousTx = _txInRange(allTx, previousRange);
    final chartData = _buildSeries(currentTx, now);
    final donutSlices = _buildCategorySlices(currentTx);
    final totalIncome =
        currentTx.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final totalExpense =
        currentTx.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final prevExpense =
        previousTx.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final netSavings = totalIncome - totalExpense;
    final pctVsPrev = prevExpense > 0
        ? ((totalExpense - prevExpense) / prevExpense) * 100
        : 0.0;
    final dayCount = currentRange.end.difference(currentRange.start).inDays + 1;
    final dailyAvg = dayCount > 0 ? totalExpense / dayCount : 0.0;

    final media = MediaQuery.of(context);
    final size = media.size;
    final topInset = media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _AnalyticsHeader(
              topInset: topInset,
              period: _period,
              metric: _metric,
              netSavings: netSavings,
              dailyAverage: dailyAvg,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              expenseDeltaPct: pctVsPrev,
              onPeriodChanged: (p) => setState(() => _period = p),
              onMetricChanged: (m) => setState(() => _metric = m),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(size.width * 0.045),
                child: Column(
                  children: [
                    // Daily Overview card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(size.width * 0.045),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Overview',
                                style: TextStyle(
                                  fontSize: size.width * 0.042,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              Row(
                                children: [
                                  _ChartTypeBtn(
                                    icon: Icons.bar_chart,
                                    active: _chartType == ChartType.bar,
                                    onTap: () => setState(
                                      () => _chartType = ChartType.bar,
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.02),
                                  _ChartTypeBtn(
                                    icon: Icons.donut_large,
                                    active: _chartType == ChartType.donut,
                                    onTap: () => setState(
                                      () => _chartType = ChartType.donut,
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.02),
                                  _ChartTypeBtn(
                                    icon: Icons.show_chart,
                                    active: _chartType == ChartType.line,
                                    onTap: () => setState(
                                      () => _chartType = ChartType.line,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: size.height * 0.008),
                          Text(
                            'Showing: ${_metric.label} • ${_period.shortLabel}',
                            style: TextStyle(
                              fontSize: size.width * 0.031,
                              color: const Color(0xFF777777),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: size.height * 0.025),
                          SizedBox(
                            height: size.height * 0.32,
                            child: _buildChart(size, chartData, donutSlices),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    Size size,
    List<_DayData> chartData,
    List<_DonutSlice> donutSlices,
  ) {
    switch (_chartType) {
      case ChartType.bar:
        return _HorizontalBarChart(data: chartData);
      case ChartType.donut:
        return _DonutChart(slices: donutSlices);
      case ChartType.line:
        return _LineChart(data: chartData);
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _AnalyticsHeader extends StatelessWidget {
  final double topInset;
  final AnalyticsPeriod period;
  final AnalyticsMetric metric;
  final double netSavings;
  final double dailyAverage;
  final double totalIncome;
  final double totalExpense;
  final double expenseDeltaPct;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;
  final ValueChanged<AnalyticsMetric> onMetricChanged;

  const _AnalyticsHeader({
    required this.topInset,
    required this.period,
    required this.metric,
    required this.netSavings,
    required this.dailyAverage,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseDeltaPct,
    required this.onPeriodChanged,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = size.width * 0.05;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        hPad,
        (topInset * 0.45) + (size.height * 0.012),
        hPad,
        size.height * 0.025,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: AhorraColors.textWhite,
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AhorraColors.textLight,
                    size: size.width * 0.06,
                  ),
                  SizedBox(width: size.width * 0.04),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.settings_outlined,
                      color: AhorraColors.textLight,
                      size: size.width * 0.06,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: size.height * 0.018),

          // Week / Month / Year toggle
          Container(
            height: size.width * 0.105,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _PeriodTab(
                  label: 'WEEK',
                  selected: period == AnalyticsPeriod.week,
                  onTap: () => onPeriodChanged(AnalyticsPeriod.week),
                ),
                _PeriodTab(
                  label: 'MONTH',
                  selected: period == AnalyticsPeriod.month,
                  onTap: () => onPeriodChanged(AnalyticsPeriod.month),
                ),
                _PeriodTab(
                  label: 'YEAR',
                  selected: period == AnalyticsPeriod.year,
                  onTap: () => onPeriodChanged(AnalyticsPeriod.year),
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.018),

          Container(
            height: size.width * 0.1,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _MetricTab(
                  label: 'EXPENSE',
                  selected: metric == AnalyticsMetric.expense,
                  onTap: () => onMetricChanged(AnalyticsMetric.expense),
                ),
                _MetricTab(
                  label: 'INCOME',
                  selected: metric == AnalyticsMetric.income,
                  onTap: () => onMetricChanged(AnalyticsMetric.income),
                ),
                _MetricTab(
                  label: 'NET',
                  selected: metric == AnalyticsMetric.net,
                  onTap: () => onMetricChanged(AnalyticsMetric.net),
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.012),

          // Stat cards row 1
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.savings_outlined,
                  label: 'Net Savings',
                  value:
                      '₱${intl.NumberFormat('#,##0.00').format(netSavings.abs())}',
                  valueColor: netSavings >= 0
                      ? const Color(0xFF2E9E5B)
                      : const Color(0xFFD94040),
                  sub: netSavings >= 0
                      ? 'Positive cash flow'
                      : 'Negative cash flow',
                  subColor: netSavings >= 0
                      ? const Color(0xFF2E9E5B)
                      : const Color(0xFFD94040),
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: _StatCard(
                  icon: Icons.calculate_outlined,
                  label: 'Daily Average',
                  value:
                      '₱${intl.NumberFormat('#,##0.00').format(dailyAverage)}',
                  sub:
                      '${expenseDeltaPct >= 0 ? '+' : ''}${expenseDeltaPct.toStringAsFixed(1)}% vs prev',
                  subColor: expenseDeltaPct > 0
                      ? const Color(0xFFD94040)
                      : const Color(0xFF2E9E5B),
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.012),

          // Stat cards row 2
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Total Income',
                  value:
                      '₱${intl.NumberFormat('#,##0.00').format(totalIncome)}',
                  valueColor: Color(0xFF2E9E5B),
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_down,
                  label: 'Total Expense',
                  value:
                      '₱${intl.NumberFormat('#,##0.00').format(totalExpense)}',
                  valueColor: Color(0xFFD94040),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AhorraColors.teal : AhorraColors.textMuted,
                fontSize: w * 0.032,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AhorraColors.teal : AhorraColors.textMuted,
                fontSize: w * 0.03,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final resolvedValue =
        value.isEmpty ? '₱${intl.NumberFormat('#,##0.00').format(0)}' : value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AhorraColors.textLight, size: w * 0.04),
              SizedBox(width: w * 0.015),
              Text(
                label,
                style: TextStyle(
                  color: AhorraColors.textLight,
                  fontSize: w * 0.028,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.015),
          Text(
            resolvedValue,
            style: TextStyle(
              color: valueColor ?? AhorraColors.textWhite,
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            SizedBox(height: w * 0.005),
            Text(
              sub!,
              style: TextStyle(
                color: subColor ?? AhorraColors.textMuted,
                fontSize: w * 0.026,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartTypeBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ChartTypeBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: MediaQuery.of(context).size.width * 0.055,
        color: active ? AhorraColors.teal : const Color(0xFFBBBBBB),
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class _DayData {
  final String label;
  final double value;
  const _DayData(this.label, this.value);
}

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  const _DonutSlice(this.label, this.value, this.color);
}

// ─── Horizontal Bar Chart ─────────────────────────────────────────────────────

class _HorizontalBarChart extends StatelessWidget {
  final List<_DayData> data;
  const _HorizontalBarChart({required this.data});

  static const List<Color> _barColors = [
    Color(0xFFE8A87C),
    Color(0xFF85C1E9),
    Color(0xFFC39BD3),
    Color(0xFFF1948A),
    Color(0xFF82E0AA),
    Color(0xFF76D7C4),
    Color(0xFFF7DC6F),
  ];

  @override
  Widget build(BuildContext context) {
    final absoluteData =
        data.map((d) => _DayData(d.label, d.value.abs())).toList();
    final double maxVal = absoluteData.isEmpty
        ? 0
        : absoluteData.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final double w = MediaQuery.of(context).size.width;
    if (absoluteData.isEmpty) {
      return Center(
        child: Text('No data yet',
            style:
                TextStyle(color: const Color(0xFF888888), fontSize: w * 0.034)),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(absoluteData.length, (i) {
        final d = absoluteData[i];
        final frac = maxVal > 0 ? d.value / maxVal : 0.0;
        return Row(
          children: [
            SizedBox(
              width: w * 0.09,
              child: Text(
                d.label,
                style: TextStyle(
                  fontSize: w * 0.028,
                  color: const Color(0xFF888888),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: w * 0.025),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) => Stack(
                  children: [
                    Container(
                      height: w * 0.055,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: w * 0.055,
                      width: constraints.maxWidth * frac,
                      decoration: BoxDecoration(
                        color: _barColors[i % _barColors.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: w * 0.02),
            SizedBox(
              width: w * 0.12,
              child: Text(
                '₱${d.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: w * 0.026,
                  color: const Color(0xFF555555),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Donut Chart ──────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final List<_DonutSlice> slices;
  const _DonutChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    if (slices.isEmpty) {
      return Center(
        child: Text('No spending categories yet',
            style:
                TextStyle(color: const Color(0xFF888888), fontSize: w * 0.034)),
      );
    }
    final double total = slices.fold(0, (s, d) => s + d.value);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: total),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.map((s) {
              final double pct = total > 0 ? (s.value / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s.label}\n${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.024,
                          color: const Color(0xFF555555),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final double total;

  const _DonutPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 * 0.9;
    final double holeRadius = radius * 0.5;
    double startAngle = -math.pi / 2;

    for (final s in slices) {
      final double sweep = total > 0 ? (s.value / total) * 2 * math.pi : 0;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          center.dx + holeRadius * math.cos(startAngle),
          center.dy + holeRadius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: holeRadius),
          startAngle + sweep,
          -sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
      startAngle += sweep;
    }

    // White center
    canvas.drawCircle(center, holeRadius - 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<_DayData> data;
  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LinePainter(data: data));
  }
}

class _LinePainter extends CustomPainter {
  final List<_DayData> data;
  const _LinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double padLeft = 40;
    const double padRight = 12;
    const double padTop = 16;
    const double padBottom = 32;

    final double chartW = size.width - padLeft - padRight;
    final double chartH = size.height - padTop - padBottom;

    final normalized =
        data.map((d) => _DayData(d.label, d.value.abs())).toList();
    final double maxVal =
        normalized.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    const double minVal = 0;
    final double valRange = maxVal - minVal;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final double y = padTop + chartH - (chartH * i / 4);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + chartW, y),
        gridPaint,
      );
      // Y labels
      final double val = minVal + (valRange * i / 4);
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(0),
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Points
    List<Offset> points = List.generate(normalized.length, (i) {
      final double x = data.length == 1
          ? padLeft + (chartW / 2)
          : padLeft + (chartW * i / (data.length - 1));
      final double y = valRange > 0
          ? padTop +
              chartH -
              (chartH * (normalized[i].value - minVal) / valRange)
          : padTop + chartH / 2;
      return Offset(x, y);
    });

    // Fill area
    final fillPath = Path()..moveTo(points.first.dx, padTop + chartH);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, padTop + chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = AhorraColors.teal.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePaint = Paint()
      ..color = AhorraColors.teal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = AhorraColors.teal;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }

    // X labels
    for (int i = 0; i < normalized.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: normalized[i].label,
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2, padTop + chartH + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
