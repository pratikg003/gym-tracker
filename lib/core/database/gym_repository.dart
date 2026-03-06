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
  Future<WorkoutExercise?> getLastExercisePerformance(
    String exerciseName,
    String currentDate,
  ) async {
    final db = await _dbHelper.database;

    // 1. Find the most recent previous exercise entry
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT we.* FROM workout_exercises we
      INNER JOIN daily_logs dl ON we.daily_log_id = dl.id
      WHERE we.exercise_name = ? AND dl.date < ?
      ORDER BY dl.date DESC
      LIMIT 1
    ''',
      [exerciseName, currentDate],
    );

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
      exercise.sets.add(
        ExerciseSet(
          id: map['id'],
          workoutExerciseId: map['workout_exercise_id'],
          weight: map['weight'],
          reps: map['reps'],
          rpe: map['rpe'],
          rir: map['rir'],
          orderIndex: map['order_index'],
        ),
      );
    }

    return exercise;
  }

  // Calculate the All-Time Best 1RM for an exercise
  Future<double> getOneRepMaxPR(String exerciseName) async {
    final db = await _dbHelper.database;

    // Formula: Weight * (1 + Reps/30)
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT MAX(es.weight * (1 + es.reps / 30.0)) as max_1rm
      FROM exercise_sets es
      INNER JOIN workout_exercises we ON es.workout_exercise_id = we.id
      WHERE we.exercise_name = ?
    ''',
      [exerciseName],
    );

    if (result.isNotEmpty && result[0]['max_1rm'] != null) {
      return result[0]['max_1rm'];
    }
    return 0.0;
  }

  // Fetch bodyweight history
  Future<List<Map<String, dynamic>>> getBodyWeightHistory() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT date, body_weight 
      FROM daily_logs 
      WHERE body_weight IS NOT NULL AND body_weight > 0
      ORDER BY date ASC
    ''');
  }

  // Fetch 1RM progression history for a specific exercise
  Future<List<Map<String, dynamic>>> getExerciseProgression(
    String exerciseName,
  ) async {
    final db = await _dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT dl.date, MAX(es.weight * (1 + es.reps / 30.0)) as max_1rm
      FROM exercise_sets es
      INNER JOIN workout_exercises we ON es.workout_exercise_id = we.id
      INNER JOIN daily_logs dl ON we.daily_log_id = dl.id
      WHERE we.exercise_name = ? AND es.reps > 0
      GROUP BY dl.date
      ORDER BY dl.date ASC
    ''',
      [exerciseName],
    );
  }

  // --- WORKOUT TEMPLATES ---

  // 1. Save a new routine
  Future<int> createTemplate(String name, List<String> exerciseNames) async {
    final db = await _dbHelper.database;
    int templateId = 0;

    // Run in a transaction so if one insert fails, they all roll back safely
    await db.transaction((txn) async {
      templateId = await txn.insert('workout_templates', {'name': name});

      for (int i = 0; i < exerciseNames.length; i++) {
        await txn.insert('template_exercises', {
          'template_id': templateId,
          'exercise_name': exerciseNames[i],
          'order_index': i,
        });
      }
    });

    return templateId;
  }

  // 2. Fetch all saved routines
  Future<List<Map<String, dynamic>>> getTemplates() async {
    final db = await _dbHelper.database;
    return await db.query('workout_templates', orderBy: 'name ASC');
  }

  // 3. Fetch the exercises inside a specific routine
  Future<List<String>> getTemplateExercises(int templateId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'template_exercises',
      columns: ['exercise_name'],
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'order_index ASC',
    );

    // Convert the list of maps straight into a clean List<String>
    return maps.map((map) => map['exercise_name'] as String).toList();
  }

  // 4. Delete a routine
  Future<void> deleteTemplate(int templateId) async {
    final db = await _dbHelper.database;
    // Because we used ON DELETE CASCADE in the table definition,
    // deleting the template automatically wipes its exercises.
    await db.delete(
      'workout_templates',
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }
}
