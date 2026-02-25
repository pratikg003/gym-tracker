import 'package:flutter/foundation.dart';
import 'package:gym_tracker/core/database/gym_repository.dart';
import 'package:gym_tracker/core/models/daily_log.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';

class WorkoutProvider with ChangeNotifier {
  final GymRepository _repository = GymRepository();

  DailyLog? _currentLog;
  bool _isLoading = false;
  String _selectedDate = DateTime.now().toString().split(' ')[0];

  DailyLog? get currentLog => _currentLog;
  bool get isLoading => _isLoading;
  String get selectedDate => _selectedDate;

  WorkoutExercise? _lastPerformance;
  WorkoutExercise? get lastPerformance => _lastPerformance;

  double _currentPR = 0.0;
  double get currentPR => _currentPR;

  //load a day's workout from SQLite into memory
  Future<void> loadLogForDate(String date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();

    //fetch the deeply nested tree
    DailyLog? log = await _repository.getDailyLogByDate(date);

    // In loadLogForDate...
    if (log == null) {
      // OLD: _currentLog = DailyLog(date: date);
      // NEW: Pass 'exercises: []' to make it a growable list
      _currentLog = DailyLog(date: date, exercises: []);
    } else {
      _currentLog = log;
    }

    _isLoading = false;
    notifyListeners();
  }

  //update body weight for current day
  Future<void> logBodyWeight(double weight) async {
    if (_currentLog == null) return;

    if (_currentLog!.id == null) {
      int id = await _repository.insertDailyLog(_selectedDate, weight);
      _currentLog = DailyLog(
        id: id,
        date: _selectedDate,
        bodyWeight: weight,
        exercises: _currentLog!.exercises,
      );
    } else {
      await _repository.updateDailyLogWeight(_currentLog!.id!, weight);
      _currentLog = DailyLog(
        id: _currentLog!.id,
        date: _selectedDate,
        bodyWeight: weight,
        exercises: _currentLog!.exercises,
      );
    }
    notifyListeners();
  }

  // add an exercise to the current day
  Future<void> addExercise(String exerciseName) async {
    if (_currentLog == null) return;

    if (_currentLog!.id == null) {
      int id = await _repository.insertDailyLog(
        _selectedDate,
        _currentLog!.bodyWeight,
      );
      _currentLog = DailyLog(
        id: id,
        date: _selectedDate,
        bodyWeight: _currentLog!.bodyWeight,
        exercises: _currentLog!.exercises,
      );
    }
    int orderIndex = _currentLog!.exercises.length;

    //save to DB
    int exerciseId = await _repository.insertWorkoutExercise(
      _currentLog!.id!,
      exerciseName,
      orderIndex,
    );

    WorkoutExercise newExercise = WorkoutExercise(
      id: exerciseId,
      dailyLogId: _currentLog!.id!,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      sets: [],
    );
    _currentLog!.exercises.add(newExercise);
    notifyListeners();
  }

  // Add multiple exercises at once from the selection screen
  Future<void> addMultipleExercises(List<String> exerciseNames) async {
    // 1. Safety Checks
    if (_currentLog == null || exerciseNames.isEmpty) return;

    int logId;

    // 2. Ensure the Daily Log exists in the Database
    if (_currentLog!.id == null) {
      // If no ID, create the log first
      logId = await _repository.insertDailyLog(
        _selectedDate,
        _currentLog!.bodyWeight,
      );

      _currentLog = DailyLog(
        id: logId,
        date: _selectedDate,
        bodyWeight: _currentLog!.bodyWeight,
        exercises: List.from(_currentLog!.exercises),
      );
    } else {
      // If ID exists, just use it
      logId = _currentLog!.id!;
    }

    // 3. Loop through exercises using the guaranteed logId
    for (String name in exerciseNames) {
      int orderIndex = _currentLog!.exercises.length;

      // Use the local 'logId' variable here, which is guaranteed to not be null
      int exerciseId = await _repository.insertWorkoutExercise(
        logId,
        name,
        orderIndex,
      );

      WorkoutExercise newExercise = WorkoutExercise(
        id: exerciseId,
        dailyLogId: logId,
        exerciseName: name,
        orderIndex: orderIndex,
        sets: [],
      );

      _currentLog!.exercises.add(newExercise);
    }

    notifyListeners();
  }

  // Add a set to a specific exercise
  Future<void> addSetToExercise(
    int exerciseIndex,
    double? weight,
    int reps,
    double? rpe,
    double? rir,
  ) async {
    if (_currentLog == null || exerciseIndex >= _currentLog!.exercises.length) {
      return;
    }

    WorkoutExercise exercise = _currentLog!.exercises[exerciseIndex];
    int orderIndex = exercise.sets.length;

    //Save to DB
    int setId = await _repository.insertExerciseSet(
      exercise.id!,
      weight,
      reps,
      rpe,
      rir,
      orderIndex,
    );

    //Update local memory
    ExerciseSet newSet = ExerciseSet(
      id: setId,
      workoutExerciseId: exercise.id!,
      reps: reps,
      rpe: rpe,
      rir: rir,
      orderIndex: orderIndex,
    );
    exercise.sets.add(newSet);

    notifyListeners();
  }

  Future<void> updateSet(
    int exerciseIndex,
    int setIndex,
    double? weight,
    int reps,
    double? rpe,
    double? rir,
  ) async {
    if (_currentLog == null) return;

    WorkoutExercise exercise = _currentLog!.exercises[exerciseIndex];
    ExerciseSet currentSet = exercise.sets[setIndex];

    // Create the updated set object
    ExerciseSet updatedSet = ExerciseSet(
      id: currentSet.id,
      workoutExerciseId: currentSet.workoutExerciseId,
      weight: weight,
      reps: reps,
      rpe: rpe,
      rir: rir,
      orderIndex: currentSet.orderIndex,
    );

    // Update Local Memory
    exercise.sets[setIndex] = updatedSet;

    // Update Database
    await _repository.updateExerciseSet(updatedSet);

    notifyListeners();
  }

  //delete exercise
  Future<void> deleteExercise(int exerciseIndex) async {
    if (_currentLog == null) return;

    WorkoutExercise exercise = _currentLog!.exercises[exerciseIndex];

    //remove from DB
    if (exercise.id != null) {
      await _repository.deleteWorkoutExercise(exercise.id!);
    }

    //remove from memory
    _currentLog!.exercises.removeAt(exerciseIndex);
    notifyListeners();
  }

  Future<void> deleteSet(int exerciseIndex, int setIndex) async {
    if (_currentLog == null) return;

    WorkoutExercise exercise = _currentLog!.exercises[exerciseIndex];
    ExerciseSet set = exercise.sets[setIndex];

    //remove from DB
    if (set.id != null) {
      await _repository.deleteExerciseSet(set.id!);
    }

    //remove from memory
    exercise.sets.removeAt(setIndex);

    // Re-index remaining sets to keep the order correct
    for (int i = 0; i < exercise.sets.length; i++) {
      exercise.sets[i] = ExerciseSet(
        id: exercise.sets[i].id,
        workoutExerciseId: exercise.sets[i].workoutExerciseId,
        weight: exercise.sets[i].weight,
        reps: exercise.sets[i].reps,
        rpe: exercise.sets[i].rpe,
        rir: exercise.sets[i].rir,
        orderIndex: i, // Update the index
      );
      await _repository.updateExerciseSet(exercise.sets[i]);
    }

    notifyListeners();
  }

  Future<void> loadExerciseHistory(String exerciseName) async {
    _lastPerformance = null; // Reset first to avoid showing wrong data
    // notifyListeners(); // Optional: uncomment if you want to show a loading spinner

    // Fetch from Repo
    WorkoutExercise? history = await _repository.getLastExercisePerformance(
      exerciseName,
      _selectedDate,
    );

    _lastPerformance = history;
    notifyListeners();
  }

  Future<void> loadPersonalRecord(String exerciseName) async {
    _currentPR = await _repository.getOneRepMaxPR(exerciseName);
    notifyListeners();
  }
}
