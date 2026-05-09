// lib/wallets_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../models/models.dart';
import '../widgets/add_wallet_modal.dart';
import 'settings_screen.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _openAddWallet(BuildContext context) async {
    final Wallet? result = await showModalBottomSheet<Wallet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWalletModal(),
    );
    if (result != null && context.mounted) {
      context.read<AppData>().addWallet(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final media = MediaQuery.of(context);
    final size = media.size;
    final hPad = size.width * 0.045;
    final topInset = media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _WalletsHeader(
              topInset: topInset,
              totalBalance: data.totalNetWorth,
              walletCount: data.wallets.length,
              onAddWallet: () => _openAddWallet(context),
            ),
            Expanded(
              child: data.wallets.isEmpty
                  ? _EmptyWallets()
                  : ListView(
                      padding: EdgeInsets.symmetric(
                          horizontal: hPad, vertical: size.height * 0.02),
                      children: [
                        Text('Wallets',
                            style: TextStyle(
                                fontSize: size.width * 0.048,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A))),
                        SizedBox(height: size.height * 0.015),
                        ...data.wallets.map((w) => _WalletCard(wallet: w)),
                        SizedBox(height: size.height * 0.04),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddWallet(context),
        backgroundColor: AhorraColors.teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _WalletsHeader extends StatelessWidget {
  final double topInset;
  final double totalBalance;
  final int walletCount;
  final VoidCallback onAddWallet;

  const _WalletsHeader(
      {required this.topInset,
      required this.totalBalance,
      required this.walletCount,
      required this.onAddWallet});

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
          (topInset * 0.45) + (size.height * 0.012), hPad, size.height * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Wallets',
                  style: TextStyle(
                      color: AhorraColors.textWhite,
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: AhorraColors.textLight, size: size.width * 0.06),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Balance',
                          style: TextStyle(
                              color: AhorraColors.textLight,
                              fontSize: size.width * 0.031)),
                      SizedBox(height: size.height * 0.008),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(totalBalance)}',
                        style: TextStyle(
                          color: AhorraColors.textWhite,
                          fontSize: size.width * 0.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.004),
                      Text(
                        '${walletCount == 0 ? 'No' : walletCount} wallet${walletCount == 1 ? '' : 's'}',
                        style: TextStyle(
                            color: AhorraColors.textMuted,
                            fontSize: size.width * 0.03),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onAddWallet,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.035,
                        vertical: size.height * 0.012),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E5),
                      borderRadius: BorderRadius.circular(size.width * 0.05),
                    ),
                    child: Text('+ Add Wallet',
                        style: TextStyle(
                            color: const Color(0xFF1A3A38),
                            fontSize: size.width * 0.032,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.008),
        ],
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              size.width * 0.05, size.height * 0.025, size.width * 0.05, 0),
          child: Text('Wallets',
              style: TextStyle(
                  fontSize: size.width * 0.048,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: size.width * 0.28, color: const Color(0xFFCCCCCC)),
                SizedBox(height: size.height * 0.025),
                Text('No wallet is set.',
                    style: TextStyle(
                        color: const Color(0xFF888888),
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: size.height * 0.006),
                Text('Set wallet to track your spending.',
                    style: TextStyle(
                        color: const Color(0xFFAAAAAA),
                        fontSize: size.width * 0.033)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: w * 0.13,
            height: w * 0.13,
            decoration: BoxDecoration(
                color: AhorraColors.teal,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(wallet.type.icon,
                    style: TextStyle(fontSize: w * 0.055))),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name,
                    style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A))),
                SizedBox(height: w * 0.005),
                Text(wallet.type.label,
                    style: TextStyle(
                        fontSize: w * 0.03, color: const Color(0xFF888888))),
              ],
            ),
          ),
          Text(
            '₱${NumberFormat('#,##0.00').format(wallet.balance)}',
            style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AhorraColors.teal),
          ),
        ],
      ),
    );
  }
}
