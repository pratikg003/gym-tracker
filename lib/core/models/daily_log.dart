import 'package:gym_tracker/core/models/workout_exercise.dart';

class DailyLog {
  final int? id;
  final String date;
  final double? bodyWeight;
  final List<WorkoutExercise> exercises;

  DailyLog({
    this.id,
    required this.date,
    this.bodyWeight,
    this.exercises = const [],
  });

  factory DailyLog.fromMap(
    Map<String, dynamic> map, {
    List<WorkoutExercise>? exercises,
  }) {
    return DailyLog(
      id: map['id'],
      date: map['date'],
      bodyWeight: map['body_weight'],
      exercises: exercises ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'date': date,
      'body_weight': bodyWeight,
    };
  }
}
