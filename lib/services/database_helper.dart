import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/product_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _useFallbackStorage = false;

  static const String _prefKeyUsers = 'shoppinghub_local_db_users';
  static const String _prefKeyWishlist = 'shoppinghub_local_db_wishlist';

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (_useFallbackStorage || kIsWeb) return null;
    if (_database != null) return _database!;

    try {
      _database = await _initDB('shoppinghub.db').timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('SQLite init timeout, using local persistent storage.');
          _useFallbackStorage = true;
          return null as dynamic;
        },
      );
      return _database;
    } catch (e) {
      debugPrint('SQLite init failed ($e), using local persistent storage.');
      _useFallbackStorage = true;
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users table for Local Database
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // 2. Wishlist table for Local Database
    await db.execute('''
      CREATE TABLE wishlist (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        thumbnail TEXT,
        brand TEXT,
        rating REAL,
        description TEXT,
        discountPercentage REAL,
        stock INTEGER
      )
    ''');

    // Default seeded user
    await db.insert('users', {'username': 'user', 'password': 'password123'});
  }

  Future<String?> registerUser(String username, String password) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) {
      return 'Username dan password tidak boleh kosong!';
    }

    try {
      final db = await database;
      if (db != null) {
        final existing = await db.query(
          'users',
          where: 'LOWER(username) = ?',
          whereArgs: [cleanUsername.toLowerCase()],
        );

        if (existing.isNotEmpty) {
          return 'Username sudah terdaftar! Gunakan username lain.';
        }

        await db.insert('users', {
          'username': cleanUsername,
          'password': password,
        });
        return null; // success
      }
    } catch (_) {
      // Fallback
    }

    return await _registerUserFallback(cleanUsername, password);
  }

  Future<bool> loginUser(String username, String password) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) return false;

    if ((cleanUsername.toLowerCase() == 'user' ||
            cleanUsername.toLowerCase() == 'admin') &&
        (password == 'password123' || password == 'admin123')) {
      return true;
    }

    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'users',
          where: 'LOWER(username) = ? AND password = ?',
          whereArgs: [cleanUsername.toLowerCase(), password],
        );
        if (result.isNotEmpty) return true;
      }
    } catch (_) {
      // Fallback
    }

    return await _loginUserFallback(cleanUsername, password);
  }

  Future<UserModel?> getUser(String username) async {
    final cleanUsername = username.trim();
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'users',
          where: 'LOWER(username) = ?',
          whereArgs: [cleanUsername.toLowerCase()],
        );
        if (result.isNotEmpty) {
          return UserModel.fromMap(result.first);
        }
      }
    } catch (_) {
      // Fallback
    }

    final users = await _getFallbackUsers();
    final match = users.where(
      (u) => u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (match.isNotEmpty) return match.first;
    return null;
  }

  // ================= WISHLIST CRUD (LOCAL DATABASE) =================
  Future<List<ProductModel>> getWishlist() async {
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query('wishlist', orderBy: 'id DESC');
        return result.map((map) => ProductModel.fromMap(map)).toList();
      }
    } catch (_) {
      // Fallback
    }

    return await _getFallbackWishlist();
  }

  Future<int> addToWishlist(ProductModel product) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.insert(
          'wishlist',
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {
      // Fallback
    }

    return await _addToFallbackWishlist(product);
  }

  Future<int> removeFromWishlist(int productId) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.delete(
          'wishlist',
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    } catch (_) {
      // Fallback
    }

    return await _removeFromFallbackWishlist(productId);
  }

  Future<bool> isInWishlist(int productId) async {
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'wishlist',
          where: 'id = ?',
          whereArgs: [productId],
        );
        return result.isNotEmpty;
      }
    } catch (_) {
      // Fallback
    }

    final list = await _getFallbackWishlist();
    return list.any((p) => p.id == productId);
  }

  // ================= FALLBACK ENGINE (PERSISTENT & ULTRA-FAST) =================
  Future<List<UserModel>> _getFallbackUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyUsers);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Seed default user
      final defaultUsers = [
        UserModel(id: 1, username: 'user', password: 'password123'),
        UserModel(id: 2, username: 'admin', password: 'admin123'),
      ];
      await prefs.setString(
        _prefKeyUsers,
        jsonEncode(defaultUsers.map((u) => u.toMap()).toList()),
      );
      return defaultUsers;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => UserModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _registerUserFallback(
    String username,
    String password,
  ) async {
    final users = await _getFallbackUsers();
    final exists = users.any(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
    );
    if (exists) {
      return 'Username sudah terdaftar! Gunakan username lain.';
    }

    users.add(
      UserModel(id: users.length + 1, username: username, password: password),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyUsers,
      jsonEncode(users.map((u) => u.toMap()).toList()),
    );
    return null;
  }

  Future<bool> _loginUserFallback(String username, String password) async {
    final users = await _getFallbackUsers();
    return users.any(
      (u) =>
          u.username.toLowerCase() == username.toLowerCase() &&
          u.password == password,
    );
  }

  Future<List<ProductModel>> _getFallbackWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyWishlist);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ProductModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> _addToFallbackWishlist(ProductModel product) async {
    final list = await _getFallbackWishlist();
    list.removeWhere((p) => p.id == product.id);
    list.insert(0, product);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyWishlist,
      jsonEncode(list.map((p) => p.toMap()).toList()),
    );
    return 1;
  }

  Future<int> _removeFromFallbackWishlist(int productId) async {
    final list = await _getFallbackWishlist();
    final before = list.length;
    list.removeWhere((p) => p.id == productId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyWishlist,
      jsonEncode(list.map((p) => p.toMap()).toList()),
    );
    return before - list.length;
  }
}
