import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "GymTracker.db";
  static const _databaseVersion = 3;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new column to the existing table without deleting data
      await db.execute(
        'ALTER TABLE daily_logs ADD COLUMN is_rest_day INTEGER DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      // Our new migration for Day 8!
      await db.execute('''
        CREATE TABLE exercise_catalog (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE,
          category TEXT
        )
      ''');

      final defaults = [
        {'name': 'Bench Press', 'category': 'Chest'},
        {'name': 'Squat', 'category': 'Legs'},
        {'name': 'Deadlift', 'category': 'Back'},
        {'name': 'Overhead Press', 'category': 'Shoulders'},
        {'name': 'Barbell Curl', 'category': 'Biceps'},
        {'name': 'Tricep Pushdown', 'category': 'Triceps'},
      ];

      for (var exercise in defaults) {
        await db.insert('exercise_catalog', exercise);
      }
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Get the physical file path of the database
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        is_rest_day INTEGER DEFAULT 0,
        body_weight REAL
        )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_log_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (daily_log_id) REFERENCES daily_logs (id) ON DELETE CASCADE
        )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        weight REAL,
        reps INTEGER NOT NULL,
        rpe REAL,
        rir REAL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises (id) ON DELETE CASCADE
        )
    ''');

    // 1. Table to store the name of the routine (e.g., "Push Day")
    await db.execute('''
      CREATE TABLE workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 2. Table to store the exercises inside that routine
    await db.execute('''
      CREATE TABLE template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (template_id) REFERENCES workout_templates (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
    CREATE TABLE exercise_catalog (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE,
      category TEXT
    )
    ''');

    final defaults = [
        // Chest
        {'name': 'Bench Press', 'category': 'Chest'},
        {'name': 'Incline Dumbbell Press', 'category': 'Chest'},
        {'name': 'Cable Fly', 'category': 'Chest'},
        {'name': 'Push-ups', 'category': 'Chest'},
        
        // Back
        {'name': 'Pull-ups', 'category': 'Back'},
        {'name': 'Lat Pulldown', 'category': 'Back'},
        {'name': 'Barbell Row', 'category': 'Back'},
        {'name': 'Deadlift', 'category': 'Back'},
        
        // Legs
        {'name': 'Squats', 'category': 'Legs'},
        {'name': 'Leg Press', 'category': 'Legs'},
        {'name': 'Romanian Deadlift', 'category': 'Legs'},
        {'name': 'Calf Raises', 'category': 'Legs'},
        {'name': 'Leg Extensions', 'category': 'Legs'},
        
        // Shoulders
        {'name': 'Overhead Press', 'category': 'Shoulders'},
        {'name': 'Lateral Raises', 'category': 'Shoulders'},
        {'name': 'Face Pulls', 'category': 'Shoulders'},
        {'name': 'Front Raises', 'category': 'Shoulders'},
        
        // Biceps
        {'name': 'Barbell Curl', 'category': 'Biceps'},
        {'name': 'Dumbbell Curl', 'category': 'Biceps'},
        {'name': 'Hammer Curl', 'category': 'Biceps'},
        {'name': 'Preacher Curl', 'category': 'Biceps'},
        
        // Triceps
        {'name': 'Tricep Pushdown', 'category': 'Triceps'},
        {'name': 'Overhead Extension', 'category': 'Triceps'},
        {'name': 'Skullcrushers', 'category': 'Triceps'},
        {'name': 'Dips', 'category': 'Triceps'},
      ];

    for (var exercise in defaults) {
      await db.insert('exercise_catalog', exercise);
    }
  }

  // Safely close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
