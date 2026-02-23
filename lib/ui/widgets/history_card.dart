import 'package:flutter/material.dart';
import '../../core/models/workout_exercise.dart';

class HistoryCard extends StatelessWidget {
  final WorkoutExercise? history;

  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey.shade100,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Last Session Performance",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Display sets as a horizontal list of chips or text
            Wrap(
              spacing: 8.0,
              children: history!.sets.map((set) {
                return Chip(
                  label: Text(
                    "${set.weight}kg x ${set.reps}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}