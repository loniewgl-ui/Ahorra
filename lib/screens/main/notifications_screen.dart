// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../utils/ahorra_colors.dart';
import 'transactions_screen.dart'; // ← add this import

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('saved_notifications') ?? '[]';
    final list = json.decode(jsonString) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', '[]');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.045;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AhorraColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: size.width * 0.25, color: Colors.grey),
                  SizedBox(height: size.width * 0.04),
                  Text('No notifications yet',
                      style: TextStyle(
                          color: Colors.grey, fontSize: size.width * 0.04)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (_, i) {
              final notif = notifications[notifications.length - 1 - i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.warning_amber,
                      color: notif['overspent'] == true
                          ? Colors.red
                          : Colors.orange),
                  title: Text(notif['title'] ?? 'Ahorra Alert'),
                  subtitle: Text(notif['body'] ?? ''),
                  onTap: () {
                    // Navigate to transaction history
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransactionsScreen()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
