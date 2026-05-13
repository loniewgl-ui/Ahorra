// lib/main_nav.dart
import 'package:flutter/material.dart';
import '../utils/ahorra_colors.dart';
import '../screens/main/analytics_screen.dart';
import '../screens/main/budgets_screen.dart';
import '../screens/main/home_screen.dart';
import '../screens/main/transactions_screen.dart';
import '../screens/main/wallets_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  static MainNavState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavState>();
  }

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    const WalletsScreen(),
    const BudgetsScreen(),
    const TransactionsScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AhorraColors.teal,
        unselectedItemColor: const Color(0xFF999999),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Wallets'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), label: 'Budgets'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
        ],
      ),
    );
  }
}
