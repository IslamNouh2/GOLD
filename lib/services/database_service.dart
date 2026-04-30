import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  
  // In-memory mock for Web to store history
  final Map<String, List<Map<String, dynamic>>> _webMockRates = {};

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dahabi.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        change REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    
    // Seed initial data to prevent empty state on first launch
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final initialRates = [
      {'symbol': 'XAU/USD', 'purchase_price': 2350.0, 'sale_price': 2350.0, 'change': 0.0, 'timestamp': now},
      {'symbol': 'USD/DZD', 'purchase_price': 238.0, 'sale_price': 240.0, 'change': 0.0, 'timestamp': now},
      {'symbol': 'EUR/DZD', 'purchase_price': 255.0, 'sale_price': 258.0, 'change': 0.0, 'timestamp': now},
    ];
    
    for (var rate in initialRates) {
      await db.insert('rates', rate);
    }
  }

  Future<void> insertRate(Map<String, dynamic> rate) async {
    if (kIsWeb) {
      if (!_webMockRates.containsKey(rate['symbol'])) {
        _webMockRates[rate['symbol']] = [];
      }
      _webMockRates[rate['symbol']]!.add(rate);
      return;
    }
    final db = await database;
    if (db != null) {
      await db.insert(
        'rates',
        rate,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLatestRates() async {
    if (kIsWeb) {
      return _webMockRates.values.map((list) => list.last).toList();
    }
    final db = await database;
    if (db == null) return [];
    
    return await db.rawQuery('''
      SELECT * FROM rates 
      WHERE id IN (SELECT MAX(id) FROM rates GROUP BY symbol)
    ''');
  }

  Future<List<Map<String, dynamic>>> getRatesBySymbol(String symbol) async {
    if (kIsWeb) {
      return _webMockRates[symbol] ?? [];
    }
    final db = await database;
    if (db == null) return [];
    return await db.query(
      'rates',
      where: 'symbol = ?',
      whereArgs: [symbol],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getRateHistory(String symbol, int limit) async {
    if (kIsWeb) {
      final list = _webMockRates[symbol] ?? [];
      return list.reversed.take(limit).toList();
    }
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'rates',
      where: 'symbol = ?',
      whereArgs: [symbol],
      orderBy: 'id DESC',
      limit: limit,
    );
  }
}
