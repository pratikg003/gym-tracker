class ExerciseSet {
  final int? id;
  final int workoutExerciseId;
  final double? weight;
  final int reps;
  final double? rpe;
  final double? rir;
  final int orderIndex;

  ExerciseSet({
    this.id,
    required this.workoutExerciseId,
    this.weight,
    required this.reps,
    this.rpe,
    this.rir,
    required this.orderIndex,
  });

  //convert a Map to User Object
  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'],
      workoutExerciseId: map['workout_exercise_id'],
      weight: map['weight'],
      reps: map['reps'],
      rpe: map['rpe'],
      rir: map['rir'],
      orderIndex: map['order_index'],
    );
  }

  //convert User object to map
  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'workout_exercise_id': workoutExerciseId,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'rir': rir,
      'order_index': orderIndex
    };
  }
}
