import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A robust local SQLite database to replace brittle SharedPreferences JSON strings.
/// This will act as the single source of truth for offline data syncing.
class LocalDatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'newmom_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // We initialize a generic key-value store table that can hold entire JSON lists
        // for seamless migration from SharedPreferences without creating 15 complex tables instantly.
        await db.execute('''
          CREATE TABLE cache_store (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheData(String key, dynamic data) async {
    try {
      final db = await database;
      await db.insert(
        'cache_store',
        {
          'key': key,
          'data': jsonEncode(data),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) print('SQLite Cache error: $e');
    }
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      final db = await database;
      final maps = await db.query(
        'cache_store',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        return jsonDecode(maps.first['data'] as String);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('SQLite Retrieve error: $e');
      return null;
    }
  }

  Future<void> clearCache(String key) async {
    final db = await database;
    await db.delete('cache_store', where: 'key = ?', whereArgs: [key]);
  }
}
