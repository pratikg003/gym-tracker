import 'package:flutter/material.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:provider/provider.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final int exerciseIndex;
  final String exerciseName;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseIndex,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exerciseName), centerTitle: true),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.currentLog == null ||
              exerciseIndex >= provider.currentLog!.exercises.length) {
            return const Text('Error loading exercise');
          }
          final WorkoutExercise exercise =
              provider.currentLog!.exercises[exerciseIndex];
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 30,
                      child: Text(
                        "Set",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "kg",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Reps",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "RPE",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "RIR",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: exercise.sets.length,
                  itemBuilder: (context, index) {
                    final set = exercise.sets[index];
                    return _SetRow(set: set, index: index + 1);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.addSetToExercise(
                        exerciseIndex,
                        null,
                        0,
                        null,
                        null,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final int index;
  const _SetRow({required this.set, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                "$index",
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // We use simple Text widgets for now.
          // On Day 64, we will turn these into input fields.
          Expanded(
            child: Center(
              child: Text(
                set.weight?.toString() ?? "-",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text("${set.reps}", style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                set.rpe?.toString() ?? "-",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                set.rir?.toString() ?? "-",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
