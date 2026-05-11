// lib/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../models/models.dart';
import '../widgets/quick_add_modal.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'All';

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddModal(),
    );
  }

  List<Transaction> _filtered(List<Transaction> all) {
    if (_filter == 'Income') return all.where((t) => !t.isExpense).toList();
    if (_filter == 'Expense') return all.where((t) => t.isExpense).toList();
    return all;
  }

  Map<String, List<Transaction>> _grouped(List<Transaction> txns) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<Transaction>> map = {};

    for (final t in txns) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      String label;
      if (d == today)
        label = 'Today';
      else if (d == yesterday)
        label = 'Yesterday';
      else
        label = DateFormat('MMM d, yyyy').format(t.date);
      map.putIfAbsent(label, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final all = data.transactions;
    final filtered = _filtered(all);
    final grouped = _grouped(filtered);
    final dates = grouped.keys.toList();
    final media = MediaQuery.of(context);
    final size = media.size;
    final topInset = media.padding.top;

    final double totalIncome =
        all.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final double totalExpense =
        all.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _TransactionsHeader(
              topInset: topInset,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              filter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.045,
                          vertical: size.height * 0.015),
                      itemCount: dates.length,
                      itemBuilder: (_, i) {
                        final date = dates[i];
                        return _DateGroup(
                            date: date, transactions: grouped[date]!);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => _openQuickAdd(context),
        backgroundColor: AhorraColors.teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  final double topInset;
  final double totalIncome;
  final double totalExpense;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _TransactionsHeader({
    required this.topInset,
    required this.totalIncome,
    required this.totalExpense,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.05;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(hPad,
          (topInset * 0.45) + (size.height * 0.012), hPad, size.height * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions',
                  style: TextStyle(
                      color: AhorraColors.textWhite,
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.w700)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen())),
                    child: Icon(Icons.notifications_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                  SizedBox(width: size.width * 0.04),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen())),
                    child: Icon(Icons.settings_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04, vertical: size.height * 0.015),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.trending_up,
                            color: const Color(0xFF4CAF50),
                            size: size.width * 0.04),
                        SizedBox(width: size.width * 0.015),
                        Text('Income',
                            style: TextStyle(
                                color: AhorraColors.textLight,
                                fontSize: size.width * 0.03)),
                      ]),
                      SizedBox(height: size.height * 0.005),
                      Text('₱${NumberFormat('#,##0.00').format(totalIncome)}',
                          style: TextStyle(
                              color: const Color(0xFF4CAF50),
                              fontSize: size.width * 0.055,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: size.height * 0.06,
                    color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: size.width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.trending_down,
                              color: const Color(0xFFD94040),
                              size: size.width * 0.04),
                          SizedBox(width: size.width * 0.015),
                          Text('Expenses',
                              style: TextStyle(
                                  color: AhorraColors.textLight,
                                  fontSize: size.width * 0.03)),
                        ]),
                        SizedBox(height: size.height * 0.005),
                        Text(
                            '₱${NumberFormat('#,##0.00').format(totalExpense)}',
                            style: TextStyle(
                                color: const Color(0xFFD94040),
                                fontSize: size.width * 0.055,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Container(
            height: size.width * 0.105,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: ['All', 'Income', 'Expense'].map((f) {
                final bool sel = filter == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onFilterChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: sel
                                ? AhorraColors.teal
                                : AhorraColors.textMuted,
                            fontSize: size.width * 0.035,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;

  const _DateGroup({required this.date, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double groupTotal = transactions.fold(
        0, (s, t) => t.isExpense ? s - t.amount : s + t.amount);
    final bool positive = groupTotal >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date,
                  style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF555555))),
              Text(
                '${positive ? '+' : ''}₱${NumberFormat('#,##0.00').format(groupTotal.abs())}',
                style: TextStyle(
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w600,
                  color: positive
                      ? const Color(0xFF2E9E5B)
                      : const Color(0xFFD94040),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: List.generate(transactions.length, (i) {
              final isLast = i == transactions.length - 1;
              return Column(
                children: [
                  _TxnRow(transaction: transactions[i]),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: w * 0.17,
                        color: const Color(0xFFF0F0F0)),
                ],
              );
            }),
          ),
        ),
        SizedBox(height: w * 0.03),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  final Transaction transaction;
  const _TxnRow({required this.transaction});

  static const Map<String, IconData> _categoryIcons = {
    'Transportation': Icons.directions_bus_outlined,
    'Food & Dining': Icons.restaurant_outlined,
    'Healthcare': Icons.local_hospital_outlined,
    'Entertainment': Icons.movie_outlined,
    'Utilities': Icons.bolt_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Rent / Housing': Icons.home_outlined,
    'Education': Icons.school_outlined,
    'Travel': Icons.flight_outlined,
    'Salary': Icons.payments_outlined,
    'Freelance': Icons.laptop_outlined,
    'Investment Return': Icons.trending_up,
    'Other': Icons.receipt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool exp = transaction.isExpense;
    final Color iconBg =
        exp ? const Color(0xFFFFEAEA) : const Color(0xFFE6F7EE);
    final Color iconColor =
        exp ? const Color(0xFFD94040) : const Color(0xFF2E9E5B);
    final IconData icon =
        _categoryIcons[transaction.category] ?? Icons.receipt_outlined;
    final String amt =
        '${exp ? '-' : '+'}₱${NumberFormat('#,##0.00').format(transaction.amount)}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
      child: Row(
        children: [
          Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: w * 0.055)),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category,
                    style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                SizedBox(height: w * 0.005),
                Text(
                  transaction.description.isNotEmpty
                      ? '${transaction.walletName} · ${transaction.description}'
                      : transaction.walletName,
                  style: TextStyle(
                      fontSize: w * 0.029, color: const Color(0xFF888888)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(amt,
              style: TextStyle(
                  fontSize: w * 0.037,
                  fontWeight: FontWeight.w700,
                  color: iconColor)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: w * 0.22, color: const Color(0xFFCCCCCC)),
          SizedBox(height: w * 0.04),
          Text('No transactions found.',
              style: TextStyle(
                  color: const Color(0xFF888888),
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: w * 0.01),
          Text('Add a transaction using the + button.',
              style: TextStyle(
                  color: const Color(0xFFAAAAAA), fontSize: w * 0.033)),
        ],
      ),
    );
  }
}
