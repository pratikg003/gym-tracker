import 'package:flutter/material.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  color: const Color(0xFF2C2C2C), // Dark theme surface
                  onSelected: (value) {
                    if (value == 'delete') {
                      context.read<WorkoutProvider>().deleteExercise(
                        exerciseIndex,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Exercise',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                final exerciseSet = exercise.sets[setIndex];

                return _SetRow(
                  key: ValueKey(exerciseSet.id),
                  exerciseIndex: exerciseIndex,
                  setIndex: setIndex,
                  exerciseSet: exerciseSet,
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

class _SetRow extends StatefulWidget {
  final int exerciseIndex;
  final int setIndex;
  final ExerciseSet exerciseSet;

  const _SetRow({
    super.key,
    required this.exerciseIndex,
    required this.setIndex,
    required this.exerciseSet,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.exerciseSet.weight != null
          ? widget.exerciseSet.weight.toString()
          : '',
    );
    _repsController = TextEditingController(
      text: widget.exerciseSet.reps > 0
          ? widget.exerciseSet.reps.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // This fires whenever the user taps away or hits 'Done'
  void _saveData() {
    double? w = double.tryParse(_weightController.text);
    int r = int.tryParse(_repsController.text) ?? 0;

    context.read<WorkoutProvider>().updateSet(
      widget.exerciseIndex,
      widget.setIndex,
      w,
      r,
      widget.exerciseSet.rpe,
      widget.exerciseSet.rir,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key!,
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<WorkoutProvider>().deleteSet(
          widget.exerciseIndex,
          widget.setIndex,
        );
      },
      // The Focus widget watches the whole row. If you tap away, it saves!
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) _saveData();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // --- SET NUMBER ---
              SizedBox(
                width: 30,
                child: Text(
                  '${widget.setIndex + 1}',
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
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // --- WEIGHT INPUT ---
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '-',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onEditingComplete: () {
                    _saveData();
                    FocusScope.of(context).unfocus(); // Close keyboard
                  },
                ),
              ),
              const SizedBox(width: 12),

              // --- REPS INPUT ---
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '-',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onEditingComplete: () {
                    _saveData();
                    FocusScope.of(context).unfocus(); // Close keyboard
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
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
