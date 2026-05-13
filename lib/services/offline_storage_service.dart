// lib/services/offline_storage_service.dart
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class OfflineStorageService {
  static sqflite.Database? _database;
  static const String _dbName = 'ahorra_offline.db';
  static const int _dbVersion = 2;

  static Future<void> initializeDatabase() async {
    if (_database != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    _database = await sqflite.openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Create wallets table
        await db.execute('''
          CREATE TABLE wallets (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        // Create transactions table
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            wallet_id TEXT NOT NULL,
            wallet_name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            is_expense INTEGER NOT NULL,
            date INTEGER NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        // Create budgets table
        await db.execute('''
          CREATE TABLE budgets (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            `limit` REAL NOT NULL,
            period TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Recreate budgets table to fix the `limit` reserved keyword issue
          await db.execute('DROP TABLE IF EXISTS budgets');
          await db.execute('''
            CREATE TABLE budgets (
              id TEXT PRIMARY KEY,
              category TEXT NOT NULL,
              `limit` REAL NOT NULL,
              period TEXT NOT NULL,
              sync_status INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  // Save individual items
  static Future<void> saveWalletLocally(Wallet wallet,
      {int syncStatus = 0}) async {
    await initializeDatabase();
    final db = _database!;

    await db.insert(
      'wallets',
      {
        'id': wallet.id,
        'name': wallet.name,
        'type': wallet.type.toString(),
        'balance': wallet.balance,
        'sync_status': syncStatus,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveTransactionLocally(Transaction transaction,
      {int syncStatus = 0}) async {
    await initializeDatabase();
    final db = _database!;

    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'wallet_id': transaction.walletId,
        'wallet_name': transaction.walletName,
        'category': transaction.category,
        'description': transaction.description,
        'amount': transaction.amount,
        'is_expense': transaction.isExpense ? 1 : 0,
        'date': transaction.date.millisecondsSinceEpoch,
        'sync_status': syncStatus,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveBudgetLocally(Budget budget,
      {int syncStatus = 0}) async {
    await initializeDatabase();
    final db = _database!;

    await db.insert(
      'budgets',
      {
        'id': budget.id,
        'category': budget.category,
        'limit': budget.limit,
        'period': budget.period.toString(),
        'sync_status': syncStatus,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  // Get local data
  static Future<List<Wallet>> getLocalWallets() async {
    await initializeDatabase();
    final db = _database!;

    final List<Map<String, dynamic>> maps = await db.query('wallets');
    return maps.map((map) => Wallet.fromJson(map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getLocalTransactions() async {
    await initializeDatabase();
    final db = _database!;

    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return maps;
  }

  static Future<List<Map<String, dynamic>>> getLocalBudgets() async {
    await initializeDatabase();
    final db = _database!;

    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return maps;
  }

  // Get unsynced data
  static Future<List<Map<String, dynamic>>> getUnsyncedData(
      String table) async {
    await initializeDatabase();
    final db = _database!;

    return await db.query(
      table,
      where: 'sync_status = 0',
    );
  }

  // Mark as synced
  static Future<void> markAsSynced(String table, String id) async {
    await initializeDatabase();
    final db = _database!;

    await db.update(
      table,
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save methods for offline storage
  static Future<void> saveLocalWallets(List<Wallet> wallets) async {
    await initializeDatabase();
    final db = _database!;

    for (final wallet in wallets) {
      await db.insert(
        'wallets',
        {
          'id': wallet.id,
          'name': wallet.name,
          'type': wallet.type.toString(),
          'balance': wallet.balance,
          'sync_status': 0,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> saveLocalTransactions(
      List<Transaction> transactions) async {
    await initializeDatabase();
    final db = _database!;

    for (final transaction in transactions) {
      await db.insert(
        'transactions',
        {
          'id': transaction.id,
          'wallet_id': transaction.walletId,
          'wallet_name': transaction.walletName,
          'category': transaction.category,
          'description': transaction.description,
          'amount': transaction.amount,
          'is_expense': transaction.isExpense ? 1 : 0,
          'date': transaction.date.millisecondsSinceEpoch,
          'sync_status': 0,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> saveLocalBudgets(List<Budget> budgets) async {
    await initializeDatabase();
    final db = _database!;

    for (final budget in budgets) {
      await db.insert(
        'budgets',
        {
          'id': budget.id,
          'category': budget.category,
          'limit': budget.limit,
          'period': budget.period.toString(),
          'sync_status': 0,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
