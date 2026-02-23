import 'package:gym_tracker/core/database/database_helper.dart';
import 'package:gym_tracker/core/models/daily_log.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';
import 'package:sqflite/sqflite.dart';

class GymRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  //INSERT OPERATIONS

  //Log a new day and log BW
  Future<int> insertDailyLog(String date, double? bodyWeight) async {
    Database db = await _dbHelper.database;
    return await db.insert('daily_logs', {
      'date': date,
      'body_weight': bodyWeight,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Add an exercise to a specific day
  Future<int> insertWorkoutExercise(
    int dailyLogId,
    String exerciseName,
    int orderIndex,
  ) async {
    Database db = await _dbHelper.database;
    return await db.insert('workout_exercises', {
      'daily_log_id': dailyLogId,
      'exercise_name': exerciseName,
      'order_index': orderIndex,
    });
  }

  //Add a specific set
  Future<int> insertExerciseSet(
    int workoutExerciseId,
    double? weight,
    int reps,
    double? rpe,
    double? rir,
    int orderIndex,
  ) async {
    Database db = await _dbHelper.database;
    return await db.insert('exercise_sets', {
      'workout_exercise_id': workoutExerciseId,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'rir': rir,
      'order_index': orderIndex,
    });
  }

  //Fetch an entire day's workout tree by date
  Future<DailyLog?> getDailyLogByDate(String date) async {
    Database db = await _dbHelper.database;

    //1. get the daily log
    List<Map<String, dynamic>> logMaps = await db.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (logMaps.isEmpty) return null;

    Map<String, dynamic> logMap = logMaps.first;
    int dailyLogId = logMap['id'];

    //2. get the exercises for this log
    List<Map<String, dynamic>> exerciseMaps = await db.query(
      'workout_exercises',
      where: 'daily_log_id = ?',
      whereArgs: [dailyLogId],
      orderBy: 'order_index ASC',
    );

    List<WorkoutExercise> exercises = [];

    //3. get the sets for each exercise
    for (var exMap in exerciseMaps) {
      int exerciseId = exMap['id'];

      List<Map<String, dynamic>> setMaps = await db.query(
        'exercise_sets',
        where: 'workout_exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'order_index ASC',
      );
      // Convert Maps to ExerciseSet objects
      List<ExerciseSet> sets = setMaps
          .map((s) => ExerciseSet.fromMap(s))
          .toList();

      // Convert Map to WorkoutExercise object, attaching the sets
      exercises.add(WorkoutExercise.fromMap(exMap, sets: sets));
      // Return the fully assembled DailyLog
    }

    return DailyLog.fromMap(logMap, exercises: exercises);
  }

  // Fetch all daily logs (Useful for plotting your bodyweight trend on the canvas later)
  Future<List<DailyLog>> getAllBodyWeights() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      where: 'body_weight IS NOT NULL',
      orderBy: 'date ASC',
    );
    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }

  // --- UPDATE OPERATIONS ---

  // Update body weight (e.g., logging a new morning weigh-in as you push from 65kg to 70kg)
  Future<int> updateDailyLogWeight(int id, double newWeight) async {
    Database db = await _dbHelper.database;
    return await db.update(
      'daily_logs',
      {'body_weight': newWeight},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update a specific set (e.g., modifying reps, weight, or RIR after completing it)
  Future<int> updateExerciseSet(ExerciseSet set) async {
    Database db = await _dbHelper.database;
    return await db.update(
      'exercise_sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  // --- DELETE OPERATIONS ---

  // Delete an entire exercise and all its sets automatically
  Future<int> deleteWorkoutExercise(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a single set
  Future<int> deleteExerciseSet(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('exercise_sets', where: 'id = ?', whereArgs: [id]);
  }

  // Fetch the last time this exercise was performed (excluding today)
  Future<WorkoutExercise?> getLastExercisePerformance(String exerciseName, String currentDate) async {
    final db = await _dbHelper.database;

    // 1. Find the most recent previous exercise entry
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT we.* FROM workout_exercises we
      INNER JOIN daily_logs dl ON we.daily_log_id = dl.id
      WHERE we.exercise_name = ? AND dl.date < ?
      ORDER BY dl.date DESC
      LIMIT 1
    ''', [exerciseName, currentDate]);

    if (maps.isEmpty) return null;

    // 2. Convert to object
    WorkoutExercise exercise = WorkoutExercise(
      id: maps[0]['id'],
      dailyLogId: maps[0]['daily_log_id'],
      exerciseName: maps[0]['exercise_name'],
      orderIndex: maps[0]['order_index'],
      sets: [], // We will fill this next
    );

    // 3. Fetch the sets for that specific past exercise
    final List<Map<String, dynamic>> setMaps = await db.query(
      'exercise_sets',
      where: 'workout_exercise_id = ?',
      whereArgs: [exercise.id],
      orderBy: 'order_index ASC',
    );

    // 4. Attach sets to the exercise
    for (var map in setMaps) {
      exercise.sets.add(ExerciseSet(
        id: map['id'],
        workoutExerciseId: map['workout_exercise_id'],
        weight: map['weight'],
        reps: map['reps'],
        rpe: map['rpe'],
        rir: map['rir'],
        orderIndex: map['order_index'],
      ));
    }

    return exercise;
  }
}
