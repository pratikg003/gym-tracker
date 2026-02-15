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

  //load a day's workout from SQLite into memory
  Future<void> loadLogForDate(String date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();

    //fetch the deeply nested tree
    DailyLog? log = await _repository.getDailyLogByDate(date);

    if (log == null) {
      _currentLog = DailyLog(date: date);
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
    );
    currentLog!.exercises.add(newExercise);
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
    if (_currentLog == null || exerciseIndex >= _currentLog!.exercises.length) return;

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
}
