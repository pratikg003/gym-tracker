import 'package:gym_tracker/core/models/exercise_set.dart';

class WorkoutExercise {
  final int? id;
  final int dailyLogId;
  final String exerciseName;
  final int orderIndex;

  final List<ExerciseSet> sets;

  WorkoutExercise({
    this.id,
    required this.dailyLogId,
    required this.exerciseName,
    required this.orderIndex,
    this.sets = const [],
  });

  factory WorkoutExercise.fromMap(
    Map<String, dynamic> map, {
    List<ExerciseSet>? sets,
  }) {
    return WorkoutExercise(
      id: map['id'],
      dailyLogId: map['daily_log_id'],
      exerciseName: map['exercise_name'],
      orderIndex: map['order_index'],
      sets: sets ?? []
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'daily_log_id': dailyLogId,
      'exercise_name': exerciseName,
      'order_index': orderIndex,
    };
  }
}
