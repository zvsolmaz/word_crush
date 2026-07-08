import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'word_crush.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            gridSize INTEGER,
            score INTEGER,
            wordCount INTEGER,
            longestWord TEXT,
            duration INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> saveGame({
    required int gridSize,
    required int score,
    required int wordCount,
    required String longestWord,
    required int duration,
  }) async {
    final db = await database;
    await db.insert('games', {
      'date': DateTime.now().toIso8601String(),
      'gridSize': gridSize,
      'score': score,
      'wordCount': wordCount,
      'longestWord': longestWord,
      'duration': duration,
    });
  }

  // ★ Tüm oyun kayıtlarını sil
  static Future<void> clearGames() async {
    final db = await database;
    await db.delete('games');
  }

  static Future<List<Map<String, dynamic>>> getGames() async {
    final db = await database;
    return await db.query('games', orderBy: 'id DESC');
  }

  static Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final games = await db.query('games');
    if (games.isEmpty) return {};

    int totalScore = games.fold(0, (sum, g) => sum + (g['score'] as int));
    int maxScore = games.map((g) => g['score'] as int).reduce(max);
    int totalWords = games.fold(0, (sum, g) => sum + (g['wordCount'] as int));
    int totalDuration = games.fold(0, (sum, g) => sum + (g['duration'] as int));
    String longestWord = games
        .map((g) => g['longestWord'] as String)
        .reduce((a, b) => a.length >= b.length ? a : b);

    return {
      'totalGames': games.length,
      'maxScore': maxScore,
      'avgScore': totalScore ~/ games.length,
      'totalWords': totalWords,
      'longestWord': longestWord,
      'totalDuration': totalDuration,
    };
  }
}

int max(int a, int b) => a > b ? a : b;