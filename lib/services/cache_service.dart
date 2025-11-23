import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CacheService {
  static final CacheService instance = CacheService._init();
  static Database? _database;

  CacheService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('api_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cacheKey TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL
      )
    ''');
    
    // Create index for faster lookups
    await db.execute('CREATE INDEX idx_cache_key ON api_cache(cacheKey)');
    await db.execute('CREATE INDEX idx_expires_at ON api_cache(expiresAt)');
  }

  String _generateCacheKey(String imageBase64) {
    final bytes = utf8.encode(imageBase64);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> cacheFaceAnalysis(String imageBase64, Map<String, dynamic> analysisData) async {
    final db = await database;
    final cacheKey = 'face_analysis_${_generateCacheKey(imageBase64)}';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30)); // Cache for 30 days

    await db.insert(
      'api_cache',
      {
        'cacheKey': cacheKey,
        'data': jsonEncode(analysisData),
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedFaceAnalysis(String imageBase64) async {
    final db = await database;
    final cacheKey = 'face_analysis_${_generateCacheKey(imageBase64)}';
    final now = DateTime.now();

    final maps = await db.query(
      'api_cache',
      where: 'cacheKey = ? AND expiresAt > ?',
      whereArgs: [cacheKey, now.toIso8601String()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['data'] as String) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> cacheMedicalSolution(String analysisKey, Map<String, dynamic> solutionData) async {
    final db = await database;
    final cacheKey = 'medical_solution_$analysisKey';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30)); // Cache for 30 days

    await db.insert(
      'api_cache',
      {
        'cacheKey': cacheKey,
        'data': jsonEncode(solutionData),
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedMedicalSolution(String analysisKey) async {
    final db = await database;
    final cacheKey = 'medical_solution_$analysisKey';
    final now = DateTime.now();

    final maps = await db.query(
      'api_cache',
      where: 'cacheKey = ? AND expiresAt > ?',
      whereArgs: [cacheKey, now.toIso8601String()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['data'] as String) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now();
    await db.delete(
      'api_cache',
      where: 'expiresAt < ?',
      whereArgs: [now.toIso8601String()],
    );
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('api_cache');
  }
}

