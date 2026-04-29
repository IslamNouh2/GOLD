import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  
  // In-memory mock for Web to prevent crashes
  final Map<String, Map<String, dynamic>> _webMockRates = {};

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
  }

  Future<void> insertRate(Map<String, dynamic> rate) async {
    if (kIsWeb) {
      _webMockRates[rate['symbol']] = rate;
      return;
    }
    final db = await database;
    if (db != null) {
      await db.insert(
        'rates',
        rate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLatestRates() async {
    if (kIsWeb) {
      return _webMockRates.values.toList();
    }
    final db = await database;
    if (db == null) return [];
    
    // Get the most recent entry for each symbol
    return await db.rawQuery('''
      SELECT * FROM rates 
      WHERE id IN (SELECT MAX(id) FROM rates GROUP BY symbol)
    ''');
  }

  Future<List<Map<String, dynamic>>> getRateHistory(String symbol, int limit) async {
    if (kIsWeb) return [];
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
