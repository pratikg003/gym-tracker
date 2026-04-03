import 'package:gym_tracker/core/models/workout_exercise.dart';

class DailyLog {
  final int? id;
  final String date;
  bool isRestDay;
  final double? bodyWeight;
  final List<WorkoutExercise> exercises;

  DailyLog({
    this.id,
    required this.date,
    this.isRestDay = false,
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
      isRestDay: map['is_rest_day'] == 1,
      exercises: exercises ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'date': date,
      'body_weight': bodyWeight,
      'is_rest_day': isRestDay ? 1 : 0,
    };
  }
}
