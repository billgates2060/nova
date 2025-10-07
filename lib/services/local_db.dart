import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Web uses default IndexedDB via sqflite_common_ffi_web indirectly; no direct import needed

class LocalDb {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    // Initialize the appropriate database factory per platform
    if (kIsWeb) {
      // On web, do not override the database factory; avoid loading sqlite3.wasm
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path;
    if (kIsWeb) {
      // On web, the name is enough; it will use IndexedDB
      path = 'nova_offline.db';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, 'nova_offline.db');
    }

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY,
            product_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            total_price REAL NOT NULL,
            sale_date TEXT NOT NULL,
            created_at TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ops_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            op TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }
}
