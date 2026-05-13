// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/ahorra_colors.dart';
import '../../utils/app_data.dart';
import '../../models/models.dart';
import '../../widgets/quick_add_modal.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'wallets_screen.dart'; // ← for direct navigation

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openQuickAdd(BuildContext context, {required bool isExpense}) {
    final data = context.read<AppData>();

    // ─── Refuse to open the modal if no wallet exists ─────────────────────
    if (data.wallets.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Wallet Found'),
          content: const Text(
            'You need at least one wallet before adding a transaction. Would you like to create one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Navigate to the wallets tab (index 1) or open wallet screen directly
                // Since we can't easily switch tabs, open the wallets screen as a full page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletsScreen()),
                );
              },
              child: const Text('Create Wallet'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddModal(startAsExpense: isExpense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final hPad = size.width * 0.045;
    final data = context.watch<AppData>();
    final topInset = media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
                data: data,
                topInset: topInset,
                onSettingsTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: hPad, vertical: size.height * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RepaintBoundary(child: _WalletsSummaryCard(data: data)),
                    SizedBox(height: size.height * 0.02),
                    RepaintBoundary(child: _MonthlyBudgetSection(data: data)),
                    SizedBox(height: size.height * 0.02),
                    _AddButtons(
                      onAddExpense: () =>
                          _openQuickAdd(context, isExpense: true),
                      onAddIncome: () =>
                          _openQuickAdd(context, isExpense: false),
                    ),
                    SizedBox(height: size.height * 0.02),
                    RepaintBoundary(
                      child: _RecentTransactions(
                          transactions: data.transactions.take(5).toList()),
                    ),
                    SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_home',
        onPressed: () => _openQuickAdd(context, isExpense: true),
        backgroundColor: AhorraColors.teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final AppData data;
  final double topInset;
  final VoidCallback onSettingsTap;

  const _HomeHeader(
      {required this.data,
      required this.topInset,
      required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.045;
    final wc = data.wallets.length;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPad,
          (topInset * 0.45) + (size.height * 0.012), hPad, size.height * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Good Day!',
                  style: TextStyle(
                      color: AhorraColors.textLight,
                      fontSize: size.width * 0.038,
                      fontWeight: FontWeight.w500)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      );
                    },
                    child: Icon(Icons.notifications_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                  SizedBox(width: size.width * 0.04),
                  GestureDetector(
                    onTap: onSettingsTap,
                    child: Icon(Icons.settings_outlined,
                        color: AhorraColors.textLight, size: size.width * 0.06),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.018),
          Center(
            child: Column(
              children: [
                Text('Total Net Worth',
                    style: TextStyle(
                        color: AhorraColors.textMuted,
                        fontSize: size.width * 0.033)),
                SizedBox(height: size.height * 0.005),
                Text(
                  '₱${NumberFormat('#,##0.00').format(data.totalNetWorth)}',
                  style: TextStyle(
                    color: data.totalNetWorth < 0
                        ? const Color(0xFFD94040)
                        : AhorraColors.textWhite,
                    fontSize: size.width * 0.115,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: size.height * 0.004),
                Text(
                  '$wc wallet${wc == 1 ? '' : 's'} total',
                  style: TextStyle(
                      color: AhorraColors.textMuted,
                      fontSize: size.width * 0.03),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: _MonthChip(
                  label: 'This Month In',
                  amount:
                      '₱${NumberFormat('#,##0.00').format(data.thisMonthIncome)}',
                  color: const Color(0xFF2E6B45),
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: _MonthChip(
                  label: 'This Month Out',
                  amount:
                      '₱${NumberFormat('#,##0.00').format(data.thisMonthExpense)}',
                  color: const Color(0xFF7A2828),
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  const _MonthChip(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.025),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: w * 0.042),
          SizedBox(width: w * 0.015),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.white70, fontSize: w * 0.028)),
                Text(amount,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wallets Summary ──────────────────────────────────────────────────────────

class _WalletsSummaryCard extends StatelessWidget {
  final AppData data;
  const _WalletsSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final wallets = data.wallets;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Wallets',
              style:
                  TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w700)),
          SizedBox(height: w * 0.03),
          if (wallets.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: w * 0.04),
              child: Center(
                child: Text('No wallets yet. Tap + to add one.',
                    style: TextStyle(
                        color: const Color(0xFF888888), fontSize: w * 0.034)),
              ),
            )
          else
            ...wallets.map((w2) => _WalletRow(wallet: w2, screenWidth: w)),
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  final Wallet wallet;
  final double screenWidth;
  const _WalletRow({required this.wallet, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final w = screenWidth;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.025),
      child: Row(
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
                color: AhorraColors.teal,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Icon(
              wallet.type.iconData, // ← Material icon
              color: Colors.white,
              size: w * 0.055,
            )),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(wallet.name,
                style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
          ),
          Text(
            '₱${NumberFormat('#,##0.00').format(wallet.balance)}',
            style: TextStyle(
                fontSize: w * 0.037,
                fontWeight: FontWeight.w700,
                color: wallet.balance < 0
                    ? const Color(0xFFD94040)
                    : AhorraColors.teal),
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Budget Progress ──────────────────────────────────────────────────

class _MonthlyBudgetSection extends StatelessWidget {
  final AppData data;
  const _MonthlyBudgetSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double totalLimit = data.currentMonthBudgetTotal;
    final double totalSpent = data.currentMonthBudgetSpent;
    final double pct =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final bool overBudget = totalSpent > totalLimit && totalLimit > 0;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget',
                  style: TextStyle(
                      fontSize: w * 0.045, fontWeight: FontWeight.w700)),
              Text(
                totalLimit > 0
                    ? '${(pct * 100).toStringAsFixed(0)}% used'
                    : 'No budget set',
                style: TextStyle(
                    color: const Color(0xFF888888), fontSize: w * 0.03),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.02),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: w * 0.03,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(
                overBudget ? const Color(0xFFD94040) : AhorraColors.teal,
              ),
            ),
          ),
          SizedBox(height: w * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₱${NumberFormat('#,##0.00').format(totalSpent)} spent',
                  style: TextStyle(
                      color: const Color(0xFF888888), fontSize: w * 0.03)),
              Text('of ₱${NumberFormat('#,##0.00').format(totalLimit)} budget',
                  style: TextStyle(
                      color: const Color(0xFF888888), fontSize: w * 0.03)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add Buttons ─────────────────────────────────────────────────────────────

class _AddButtons extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  const _AddButtons({required this.onAddExpense, required this.onAddIncome});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
            child: _ActionButton(
                label: 'Add Expense',
                icon: Icons.arrow_circle_down,
                iconColor: const Color(0xFFD94040),
                onTap: onAddExpense)),
        SizedBox(width: w * 0.03),
        Expanded(
            child: _ActionButton(
                label: 'Add Income',
                icon: Icons.arrow_circle_up,
                iconColor: const Color(0xFF2E9E5B),
                onTap: onAddIncome)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.05),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: w * 0.09),
              SizedBox(height: w * 0.02),
              Text(label,
                  style: TextStyle(
                      fontSize: w * 0.036, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  const _RecentTransactions({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions',
              style:
                  TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w700)),
          SizedBox(height: w * 0.04),
          if (transactions.isEmpty) _EmptyTransactions(),
          ...transactions.map((t) => _TransactionRow(transaction: t)),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                color: const Color(0xFFCCCCCC), size: w * 0.14),
            SizedBox(height: w * 0.03),
            Text('No transactions yet',
                style: TextStyle(
                    color: const Color(0xFF888888),
                    fontSize: w * 0.036,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: w * 0.01),
            Text('Add your first transaction to get started',
                style: TextStyle(
                    color: const Color(0xFFAAAAAA), fontSize: w * 0.03)),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool exp = transaction.isExpense;
    final Color iconBg =
        exp ? const Color(0xFFFFEAEA) : const Color(0xFFE6F7EE);
    final Color iconColor =
        exp ? const Color(0xFFD94040) : const Color(0xFF2E9E5B);
    final IconData icon = exp ? Icons.arrow_circle_down : Icons.arrow_circle_up;
    final String amt =
        '${exp ? '-' : '+'}₱${NumberFormat('#,##0.00').format(transaction.amount)}';
    final String dateStr = DateFormat('MMM d').format(transaction.date);

    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.035),
      child: Row(
        children: [
          Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: w * 0.06)),
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
                Text(transaction.walletName,
                    style: TextStyle(
                        fontSize: w * 0.029, color: const Color(0xFF888888))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amt,
                  style: TextStyle(
                      fontSize: w * 0.037,
                      fontWeight: FontWeight.w700,
                      color: iconColor)),
              SizedBox(height: w * 0.005),
              Text(dateStr,
                  style: TextStyle(
                      fontSize: w * 0.029, color: const Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}
