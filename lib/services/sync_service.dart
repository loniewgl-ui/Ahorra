// lib/services/sync_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';
import '../models/models.dart';

class SyncService {
  static bool _isSyncing = false;
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  static Future<void> initializeSync() async {
    // Listen for connectivity changes
    _connectivitySubscription =
        ConnectivityService.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        _syncWhenOnline();
      }
    });

    // Initial sync when app starts
    if (await ConnectivityService.isConnected) {
      await _syncWhenOnline();
    }
  }

  static Future<void> _syncWhenOnline() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      // Sync wallets
      await _syncWallets();

      // Sync transactions
      await _syncTransactions();

      // Sync budgets
      await _syncBudgets();
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _syncWallets() async {
    try {
      // Get unsynced local wallets
      final unsyncedWallets =
          await OfflineStorageService.getUnsyncedData('wallets');

      for (final walletData in unsyncedWallets) {
        try {
          final wallet = Wallet.fromJson(walletData);

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('wallets')
              .doc(wallet.id)
              .set(wallet.toJson());

          // Mark as synced locally
          await OfflineStorageService.markAsSynced('wallets', wallet.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing wallet ${walletData['id']}: $e');
          }
        }
      }

      // Sync from Firestore to local
      await _syncWalletsFromFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Error in wallet sync: $e');
      }
    }
  }

  static Future<void> _syncTransactions() async {
    try {
      // Get unsynced local transactions
      final unsyncedTransactions =
          await OfflineStorageService.getUnsyncedData('transactions');

      for (final transactionData in unsyncedTransactions) {
        try {
          final transaction = Transaction.fromJson(transactionData);

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('transactions')
              .doc(transaction.id)
              .set(transaction.toJson());

          // Mark as synced locally
          await OfflineStorageService.markAsSynced(
              'transactions', transaction.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing transaction ${transactionData['id']}: $e');
          }
        }
      }

      // Sync from Firestore to local
      await _syncTransactionsFromFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Error in transaction sync: $e');
      }
    }
  }

  static Future<void> _syncBudgets() async {
    try {
      // Get unsynced local budgets
      final unsyncedBudgets =
          await OfflineStorageService.getUnsyncedData('budgets');

      for (final budgetData in unsyncedBudgets) {
        try {
          final budget = Budget.fromJson(budgetData);

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('budgets')
              .doc(budget.id)
              .set(budget.toJson());

          // Mark as synced locally
          await OfflineStorageService.markAsSynced('budgets', budget.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing budget ${budgetData['id']}: $e');
          }
        }
      }

      // Sync from Firestore to local
      await _syncBudgetsFromFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Error in budget sync: $e');
      }
    }
  }

  static Future<void> _syncWalletsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('wallets')
          .get();

      for (final doc in snapshot.docs) {
        final walletData = doc.data();
        final wallet = Wallet.fromJson(walletData);

        await OfflineStorageService.saveWalletLocally(wallet, syncStatus: 1);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing wallets from Firestore: $e');
      }
    }
  }

  static Future<void> _syncTransactionsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(100) // Limit to recent transactions
          .get();

      for (final doc in snapshot.docs) {
        final transactionData = doc.data();
        final transaction = Transaction.fromJson(transactionData);

        await OfflineStorageService.saveTransactionLocally(transaction,
            syncStatus: 1);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing transactions from Firestore: $e');
      }
    }
  }

  static Future<void> _syncBudgetsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('budgets')
          .get();

      for (final doc in snapshot.docs) {
        final budgetData = doc.data();
        final budget = Budget.fromJson(budgetData);

        await OfflineStorageService.saveBudgetLocally(budget, syncStatus: 1);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing budgets from Firestore: $e');
      }
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _isSyncing = false;
  }
}
