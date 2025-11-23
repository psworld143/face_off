import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/analysis_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('face_analysis.db');
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
      CREATE TABLE analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attractivenessScore REAL NOT NULL,
        bestAngle TEXT NOT NULL,
        bestAngleDescription TEXT NOT NULL,
        overallAnalysis TEXT NOT NULL,
        imageBase64 TEXT NOT NULL,
        facialFeaturesJson TEXT NOT NULL,
        medicalCondition TEXT NOT NULL,
        medicalSeverity TEXT NOT NULL,
        medicalDescription TEXT NOT NULL,
        medicalRecommendationsJson TEXT NOT NULL,
        medicalTreatmentsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertAnalysis(AnalysisHistory history) async {
    final db = await database;
    return await db.insert('analysis_history', history.toMap());
  }

  Future<int> updateAnalysis(AnalysisHistory history) async {
    final db = await database;
    return await db.update(
      'analysis_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<AnalysisHistory?> getTodayAnalysis() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final maps = await db.query(
      'analysis_history',
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [
        todayStart.toIso8601String(),
        todayEnd.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AnalysisHistory.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AnalysisHistory>> getAllAnalyses() async {
    final db = await database;
    final maps = await db.query(
      'analysis_history',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => AnalysisHistory.fromMap(map)).toList();
  }

  Future<AnalysisHistory?> getAnalysisById(int id) async {
    final db = await database;
    final maps = await db.query(
      'analysis_history',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AnalysisHistory.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAnalysis(int id) async {
    final db = await database;
    return await db.delete(
      'analysis_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllAnalyses() async {
    final db = await database;
    return await db.delete('analysis_history');
  }

  Future<int> getAnalysisCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM analysis_history');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

