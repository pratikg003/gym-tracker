import 'package:flutter/material.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:provider/provider.dart';

class ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    'Set',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Weight',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Reps',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 40), // Space for the checkmark icon
              ],
            ),
            const SizedBox(height: 8),

            // --- 3. THE SETS LIST ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.sets.length,
              itemBuilder: (context, setIndex) {
                final exerciseSet =
                    exercise.sets[setIndex]; // We are using this now!

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      // --- SET NUMBER ---
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${setIndex + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // --- PREVIOUS DATA PILL ---
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2C2C2C,
                            ), // Dark grey pill background
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '-', // We will wire this up to past workout data later
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // --- WEIGHT INPUT ---
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            // Use the actual data or show a dash
                            hintText: exerciseSet.weight != null
                                ? exerciseSet.weight.toString()
                                : '-',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(
                              0xFF2C2C2C,
                            ), // Dark grey input background
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onFieldSubmitted: (value) {
                            double? newWeight = double.tryParse(value);
                            context.read<WorkoutProvider>().updateSet(
                              exerciseIndex,
                              setIndex,
                              newWeight,
                              exerciseSet.reps,
                              exerciseSet.rpe,
                              exerciseSet.rir,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // --- REPS INPUT ---
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            // Use the actual data or show a dash
                            hintText: exerciseSet.reps > 0
                                ? exerciseSet.reps.toString()
                                : '-',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(
                              0xFF2C2C2C,
                            ), // Dark grey input background
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onFieldSubmitted: (value) {
                            int newReps = int.tryParse(value) ?? 0;
                            context.read<WorkoutProvider>().updateSet(
                              exerciseIndex,
                              setIndex,
                              exerciseSet.weight,
                              newReps,
                              exerciseSet.rpe,
                              exerciseSet.rir,
                            );
                          },
                        ),
                      ),

                      // --- CHECKMARK SPACE ---
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.check_box_outline_blank,
                            color: Colors.grey,
                            size: 24,
                          ),
                          onPressed: () {
                            // We will add the logic to mark the set as "complete" here
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Add Set",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  context.read<WorkoutProvider>().addSetToExercise(
                    exerciseIndex,
                    null,
                    0,
                    null,
                    null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
