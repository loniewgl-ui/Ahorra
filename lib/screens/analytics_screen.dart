// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../models/models.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

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

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  AnalyticsPeriod _period = AnalyticsPeriod.week;
  ChartType _chartType = ChartType.bar;
  AnalyticsMetric _metric = AnalyticsMetric.expense;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onPeriodChanged(AnalyticsPeriod period) {
    _slideController.forward(from: 0.0);
    setState(() => _period = period);
  }

  void _onMetricChanged(AnalyticsMetric metric) {
    _slideController.forward(from: 0.0);
    setState(() => _metric = metric);
  }

  DateTimeRange _rangeFor(AnalyticsPeriod period, DateTime now) {
    if (period == AnalyticsPeriod.week) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
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
    return all.where((t) {
      final dateOnly = DateTime(t.date.year, t.date.month, t.date.day);
      return !dateOnly.isBefore(range.start) && !dateOnly.isAfter(range.end);
    }).toList();
  }

  List<_DayData> _buildSeries(List<Transaction> txns, DateTime now) {
    double _getValue(Transaction t) {
      if (_metric == AnalyticsMetric.expense) return t.isExpense ? t.amount : 0;
      if (_metric == AnalyticsMetric.income) return t.isExpense ? 0 : t.amount;
      return t.isExpense ? -t.amount : t.amount;
    }

    if (_period == AnalyticsPeriod.week) {
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final values = List<double>.filled(7, 0.0);
      for (final t in txns) {
        int idx = t.date.weekday - 1;
        if (idx < 0) idx = 0;
        if (idx > 6) idx = 6;
        values[idx] += _getValue(t);
      }
      return List.generate(7, (i) => _DayData(labels[i], values[i].abs()));
    }

    if (_period == AnalyticsPeriod.month) {
      final values = List<double>.filled(5, 0.0);
      for (final t in txns) {
        final idx = ((t.date.day - 1) ~/ 7).clamp(0, 4);
        values[idx] += _getValue(t);
      }
      return List.generate(5, (i) => _DayData('Wk${i + 1}', values[i].abs()));
    }

    final values = List<double>.filled(12, 0.0);
    for (final t in txns) {
      final idx = (t.date.month - 1).clamp(0, 11);
      values[idx] += _getValue(t);
    }
    return List.generate(
        12,
        (i) => _DayData(
            intl.DateFormat('MMM').format(DateTime(now.year, i + 1)),
            values[i].abs()));
  }

  List<_DonutSlice> _buildCategorySlices(List<Transaction> txns) {
    if (_metric == AnalyticsMetric.net) {
      final income =
          txns.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final expense =
          txns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
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
    for (final t in txns.where((e) =>
        _metric == AnalyticsMetric.expense ? e.isExpense : !e.isExpense)) {
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
        (i) =>
            _DonutSlice(top[i].key, top[i].value, palette[i % palette.length]));
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
              onPeriodChanged: _onPeriodChanged,
              onMetricChanged: _onMetricChanged,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.045,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _slideController.drive(
                        Tween<double>(begin: 0.7, end: 1.0),
                      ),
                      child: SlideTransition(
                        position: _slideController.drive(
                          Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(size.width * 0.045),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daily Overview',
                                    style: TextStyle(
                                      fontSize: size.width * 0.048,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.01,
                                      vertical: size.width * 0.008,
                                    ),
                                    child: Row(
                                      children: [
                                        _ChartTypeBtn(
                                          icon: Icons.bar_chart,
                                          active: _chartType == ChartType.bar,
                                          onTap: () => setState(
                                              () => _chartType = ChartType.bar),
                                        ),
                                        SizedBox(width: size.width * 0.01),
                                        _ChartTypeBtn(
                                          icon: Icons.donut_large,
                                          active: _chartType == ChartType.donut,
                                          onTap: () => setState(() =>
                                              _chartType = ChartType.donut),
                                        ),
                                        SizedBox(width: size.width * 0.01),
                                        _ChartTypeBtn(
                                          icon: Icons.show_chart,
                                          active: _chartType == ChartType.line,
                                          onTap: () => setState(() =>
                                              _chartType = ChartType.line),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.012),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.03,
                                  vertical: size.height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Showing: ${_metric.label} • ${_period.shortLabel}',
                                  style: TextStyle(
                                    fontSize: size.width * 0.034,
                                    color: const Color(0xFF888888),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.025),
                              SizedBox(
                                height: size.height * 0.38,
                                child: currentTx.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: size.width * 0.12,
                                              color: const Color(0xFFCCCCCC),
                                            ),
                                            SizedBox(
                                                height: size.height * 0.015),
                                            Text(
                                              'No transactions in this period',
                                              style: TextStyle(
                                                color: const Color(0xFF888888),
                                                fontSize: size.width * 0.035,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _buildChart(size, chartData, donutSlices),
                              ),
                            ],
                          ),
                        ),
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
      Size size, List<_DayData> chartData, List<_DonutSlice> donutSlices) {
    switch (_chartType) {
      case ChartType.bar:
        return _HorizontalBarChart(data: chartData);
      case ChartType.donut:
        return _DonutChart(slices: donutSlices);
      case ChartType.line:
        return _LineChart(data: chartData, period: _period);
    }
  }
}

// ─── Enhanced Header with Smooth Animations ───────────────────────────────
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: AhorraColors.textWhite,
                  fontSize: size.width * 0.068,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: [
                  _HeaderIconBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.04),
                  _HeaderIconBtn(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.018),
          _AnimatedTabGroup(
            selectedPeriod: period,
            onPeriodChanged: onPeriodChanged,
            selectedMetric: metric,
            onMetricChanged: onMetricChanged,
          ),
          SizedBox(height: size.height * 0.016),
          _StatCardsRow(
            netSavings: netSavings,
            dailyAverage: dailyAverage,
            expenseDeltaPct: expenseDeltaPct,
          ),
          SizedBox(height: size.height * 0.012),
          _TotalsRow(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          ),
        ],
      ),
    );
  }
}

// ─── Animated Tab Group ───────────────────────────────────────────────────
class _AnimatedTabGroup extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;
  final AnalyticsMetric selectedMetric;
  final ValueChanged<AnalyticsMetric> onMetricChanged;

  const _AnimatedTabGroup({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          height: size.width * 0.11,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _PeriodTab(
                label: 'WEEK',
                selected: selectedPeriod == AnalyticsPeriod.week,
                onTap: () => onPeriodChanged(AnalyticsPeriod.week),
              ),
              _PeriodTab(
                label: 'MONTH',
                selected: selectedPeriod == AnalyticsPeriod.month,
                onTap: () => onPeriodChanged(AnalyticsPeriod.month),
              ),
              _PeriodTab(
                label: 'YEAR',
                selected: selectedPeriod == AnalyticsPeriod.year,
                onTap: () => onPeriodChanged(AnalyticsPeriod.year),
              ),
            ],
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Container(
          height: size.width * 0.11,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _MetricTab(
                label: 'EXPENSE',
                selected: selectedMetric == AnalyticsMetric.expense,
                onTap: () => onMetricChanged(AnalyticsMetric.expense),
              ),
              _MetricTab(
                label: 'INCOME',
                selected: selectedMetric == AnalyticsMetric.income,
                onTap: () => onMetricChanged(AnalyticsMetric.income),
              ),
              _MetricTab(
                label: 'NET',
                selected: selectedMetric == AnalyticsMetric.net,
                onTap: () => onMetricChanged(AnalyticsMetric.net),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat Cards Row ───────────────────────────────────────────────────────
class _StatCardsRow extends StatelessWidget {
  final double netSavings;
  final double dailyAverage;
  final double expenseDeltaPct;

  const _StatCardsRow({
    required this.netSavings,
    required this.dailyAverage,
    required this.expenseDeltaPct,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        Expanded(
          child: _AnimatedStatCard(
            delay: 0,
            icon: Icons.savings_outlined,
            label: 'Net Savings',
            value: '₱${intl.NumberFormat('#,##0.00').format(netSavings.abs())}',
            valueColor: netSavings >= 0
                ? const Color(0xFF2E9E5B)
                : const Color(0xFFD94040),
            sub: netSavings >= 0 ? 'Positive cash flow' : 'Negative cash flow',
            subColor: netSavings >= 0
                ? const Color(0xFF2E9E5B)
                : const Color(0xFFD94040),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: _AnimatedStatCard(
            delay: 100,
            icon: Icons.calculate_outlined,
            label: 'Daily Average',
            value: '₱${intl.NumberFormat('#,##0.00').format(dailyAverage)}',
            sub:
                '${expenseDeltaPct >= 0 ? '+' : ''}${expenseDeltaPct.toStringAsFixed(1)}% vs prev',
            subColor: expenseDeltaPct > 0
                ? const Color(0xFFD94040)
                : const Color(0xFF2E9E5B),
          ),
        ),
      ],
    );
  }
}

// ─── Totals Row ───────────────────────────────────────────────────────────
class _TotalsRow extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const _TotalsRow({
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        Expanded(
          child: _AnimatedStatCard(
            delay: 200,
            icon: Icons.trending_up,
            label: 'Total Income',
            value: '₱${intl.NumberFormat('#,##0.00').format(totalIncome)}',
            valueColor: const Color(0xFF2E9E5B),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: _AnimatedStatCard(
            delay: 300,
            icon: Icons.trending_down,
            label: 'Total Expense',
            value: '₱${intl.NumberFormat('#,##0.00').format(totalExpense)}',
            valueColor: const Color(0xFFD94040),
          ),
        ),
      ],
    );
  }
}

// ─── Animated Stat Card ───────────────────────────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final int delay;
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;
  final Color? valueColor;

  const _AnimatedStatCard({
    required this.delay,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
    this.valueColor,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _StatCard(
          icon: widget.icon,
          label: widget.label,
          value: widget.value,
          sub: widget.sub,
          subColor: widget.subColor,
          valueColor: widget.valueColor,
        ),
      ),
    );
  }
}

// ─── Header Icon Button ───────────────────────────────────────────────────
class _HeaderIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeaderIconBtn> createState() => _HeaderIconBtnState();
}

class _HeaderIconBtnState extends State<_HeaderIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 0.92).animate(_controller),
      child: GestureDetector(
        onTap: _handleTap,
        child: Icon(
          widget.icon,
          color: AhorraColors.textLight,
          size: size.width * 0.065,
        ),
      ),
    );
  }
}

// ─── Period Tab ───────────────────────────────────────────────────────────
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
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.all(w * 0.01),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AhorraColors.teal : AhorraColors.textMuted,
                fontSize: w * 0.032,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Metric Tab ───────────────────────────────────────────────────────────
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
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.all(w * 0.01),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AhorraColors.teal : AhorraColors.textMuted,
                fontSize: w * 0.032,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.035,
        vertical: w * 0.035,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AhorraColors.textLight, size: w * 0.042),
              SizedBox(width: w * 0.02),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AhorraColors.textLight,
                    fontSize: w * 0.029,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.018),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AhorraColors.textWhite,
              fontSize: w * 0.052,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (sub != null) ...[
            SizedBox(height: w * 0.006),
            Text(
              sub!,
              style: TextStyle(
                color: subColor ?? AhorraColors.textMuted,
                fontSize: w * 0.027,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Chart Type Button ───────────────────────────────────────────────────
class _ChartTypeBtn extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ChartTypeBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ChartTypeBtn> createState() => _ChartTypeBtnState();
}

class _ChartTypeBtnState extends State<_ChartTypeBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.88).animate(_controller),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.015),
          child: Icon(
            widget.icon,
            size: size * 0.06,
            color: widget.active ? AhorraColors.teal : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

// ─── Chart Data Classes ───────────────────────────────────────────────────
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

// ─── Horizontal Bar Chart (Enhanced) ───────────────────────────────────────
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
    final double maxVal = data.isEmpty
        ? 0
        : data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final double w = MediaQuery.of(context).size.width;

    if (data.isEmpty || maxVal == 0) {
      return Center(
        child: Text(
          'No data yet',
          style: TextStyle(
            color: const Color(0xFF888888),
            fontSize: w * 0.035,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(data.length, (i) {
        final d = data[i];
        final frac = (d.value / maxVal).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.012),
          child: Row(
            children: [
              SizedBox(
                width: w * 0.11,
                child: Text(
                  d.label,
                  style: TextStyle(
                    fontSize: w * 0.029,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) => Stack(
                    children: [
                      Container(
                        height: w * 0.058,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        height: w * 0.058,
                        width: constraints.maxWidth * frac,
                        decoration: BoxDecoration(
                          color: _barColors[i % _barColors.length],
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: _barColors[i % _barColors.length]
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              SizedBox(
                width: w * 0.14,
                child: Text(
                  '₱${d.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: w * 0.028,
                    color: const Color(0xFF555555),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Donut Chart (Enhanced) ───────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final List<_DonutSlice> slices;

  const _DonutChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    if (slices.isEmpty) {
      return Center(
        child: Text(
          'No spending categories yet',
          style: TextStyle(
            color: const Color(0xFF888888),
            fontSize: w * 0.035,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final double total = slices.fold(0.0, (s, d) => s + d.value);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: total),
            size: Size(w * 0.35, w * 0.35),
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
                  padding: EdgeInsets.symmetric(vertical: w * 0.008),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: s.color.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.012),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: TextStyle(
                                fontSize: w * 0.026,
                                color: const Color(0xFF555555),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: w * 0.023,
                                color: const Color(0xFF999999),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ));
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

      final shadowPaint = Paint()
        ..color = s.color.withOpacity(0.2)
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

      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
      startAngle += sweep;
    }

    canvas.drawCircle(center, holeRadius - 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─── Line Chart (Fixed with Better Label Handling) ─────────────────────────
class _LineChart extends StatelessWidget {
  final List<_DayData> data;
  final AnalyticsPeriod period;

  const _LineChart({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    return CustomPaint(
      painter: _LinePainter(data: data, period: period),
      size: Size.infinite,
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<_DayData> data;
  final AnalyticsPeriod period;

  const _LinePainter({required this.data, required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double padLeft = 45, padRight = 15, padTop = 20, padBottom = 50;
    final double chartW = size.width - padLeft - padRight;
    final double chartH = size.height - padTop - padBottom;

    final double maxVal =
        data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final double minVal = 0.0;
    final double valRange = maxVal - minVal;

    // Grid lines with better styling
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

      final double val = minVal + (valRange * i / 4);
      final tp = TextPainter(
        text: TextSpan(
          text: '₱${val.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(padLeft - tp.width - 8, y - tp.height / 2));
    }

    // Calculate points
    final points = List.generate(data.length, (i) {
      final double x = data.length == 1
          ? padLeft + (chartW / 2)
          : padLeft + (chartW * i / (data.length - 1));
      final double y = valRange > 0
          ? padTop + chartH - (chartH * (data[i].value - minVal) / valRange)
          : padTop + chartH / 2;
      return Offset(x, y);
    });

    // Fill area with gradient
    final fillPath = Path()..moveTo(points.first.dx, padTop + chartH);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, padTop + chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = AhorraColors.teal.withOpacity(0.08)
        ..style = PaintingStyle.fill,
    );

    // Line with smooth curve
    final linePaint = Paint()
      ..color = AhorraColors.teal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++)
      linePath.lineTo(points[i].dx, points[i].dy);

    canvas.drawPath(linePath, linePaint);

    // Dots with glow effect
    for (final p in points) {
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = AhorraColors.teal.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        2.5,
        Paint()
          ..color = AhorraColors.teal
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        2.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // X-axis labels with smart spacing
    final labelSpacing = _getOptimalLabelSpacing(data.length);
    for (int i = 0; i < data.length; i++) {
      if (i % labelSpacing == 0 || data.length <= 7) {
        final tp = TextPainter(
          text: TextSpan(
            text: data[i].label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(
            points[i].dx - tp.width / 2,
            padTop + chartH + 12,
          ),
        );
      }
    }
  }

  int _getOptimalLabelSpacing(int dataCount) {
    if (dataCount <= 7) return 1;
    if (dataCount <= 12) return 2;
    return 3;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
