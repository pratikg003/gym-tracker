import 'package:flutter/material.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:provider/provider.dart';

class ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  @override
  void initState() {
    super.initState();
    // Fetch previous performance when the card loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadExerciseHistory(
        widget.exercise.exerciseName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read the history from our new map
    final pastPerformance = context
        .watch<WorkoutProvider>()
        .pastPerformances[widget.exercise.exerciseName];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EXERCISE HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.exercise.exerciseName, // Note: added 'widget.' here
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  color: const Color(0xFF2C2C2C),
                  onSelected: (value) {
                    if (value == 'delete') {
                      context.read<WorkoutProvider>().deleteExercise(
                        widget.exerciseIndex,
                      ); // added 'widget.'
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

            // --- COLUMN HEADERS (Keep your existing Row here) ---
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
                  width: 55,
                  child: Text(
                    'kg',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 45,
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
                SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    'RPE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    'RIR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),

            // --- 3. THE SETS LIST ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.exercise.sets.length, // added 'widget.'
              itemBuilder: (context, setIndex) {
                final exerciseSet =
                    widget.exercise.sets[setIndex]; // added 'widget.'

                // Grab the corresponding set from the previous session if it exists
                ExerciseSet? pastSet;
                if (pastPerformance != null &&
                    setIndex < pastPerformance.sets.length) {
                  pastSet = pastPerformance.sets[setIndex];
                }

                return _SetRow(
                  key: ValueKey(exerciseSet.id),
                  exerciseIndex: widget.exerciseIndex, // added 'widget.'
                  setIndex: setIndex,
                  exerciseSet: exerciseSet,
                  pastSet: pastSet, // <--- Pass it down!
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
                    widget.exerciseIndex, // added 'widget.'
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
  final ExerciseSet? pastSet;

  const _SetRow({
    super.key,
    required this.exerciseIndex,
    required this.setIndex,
    required this.exerciseSet,
    this.pastSet,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _rpeController;
  late TextEditingController _rirController;

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
    _rpeController = TextEditingController(
      text: widget.exerciseSet.rpe != null
          ? widget.exerciseSet.rpe.toString()
          : '',
    );
    _rirController = TextEditingController(
      text: widget.exerciseSet.rir != null
          ? widget.exerciseSet.rir.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  // This fires whenever the user taps away or hits 'Done'
  void _saveData() {
    double? w = double.tryParse(_weightController.text);
    int r = int.tryParse(_repsController.text) ?? 0;
    double? rpe = double.tryParse(_rpeController.text);
    double? rir = double.tryParse(_rirController.text);

    context.read<WorkoutProvider>().updateSet(
      widget.exerciseIndex,
      widget.setIndex,
      w,
      r,
      rpe,
      rir,
    );
  }

  // Helper method to keep text fields clean and consistent
  Widget _buildCompactTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 2,
        ), // Tighter padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      onEditingComplete: () {
        _saveData();
        FocusScope.of(context).unfocus(); // Close keyboard
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String previousText = '-';
    if (widget.pastSet != null && widget.pastSet!.reps > 0) {
      String w = widget.pastSet!.weight != null 
          ? '${widget.pastSet!.weight}kg' 
          : 'BW';
      previousText = '$w x ${widget.pastSet!.reps}';
    }
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
                  child: Text(
                    previousText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // --- WEIGHT INPUT ---
              SizedBox(
                width: 55,
                child: _buildCompactTextField(_weightController, '-'),
              ),
              const SizedBox(width: 8),

              // --- REPS INPUT ---
              SizedBox(
                width: 45,
                child: _buildCompactTextField(_repsController, '-'),
              ),
              const SizedBox(width: 8),

              // --- RPE INPUT ---
              SizedBox(
                width: 45,
                child: _buildCompactTextField(_rpeController, '-'),
              ),
              const SizedBox(width: 8),

              // --- RIR INPUT ---
              SizedBox(
                width: 45,
                child: _buildCompactTextField(_rirController, '-'),
              ),

              // --- CHECKMARK SPACE ---
              const SizedBox(width: 6),
              // SizedBox(
              //   width: 32,
              //   child: IconButton(
              //     padding: EdgeInsets.zero,
              //     icon: const Icon(
              //       Icons.check_box_outline_blank,
              //       color: Colors.grey,
              //       size: 24,
              //     ),
              //     onPressed: () {}, // We will wire this up later!
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
