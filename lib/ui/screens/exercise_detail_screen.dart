import 'package:flutter/material.dart';
import 'package:gym_tracker/core/models/exercise_set.dart';
import 'package:gym_tracker/core/models/workout_exercise.dart';
import 'package:gym_tracker/core/providers/timer_provider.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:gym_tracker/core/utils/one_rep_max.dart';
import 'package:gym_tracker/ui/widgets/history_card.dart';
import 'package:gym_tracker/ui/widgets/rest_timer_banner.dart';
import 'package:provider/provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseIndex;
  final String exerciseName;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseIndex,
    required this.exerciseName,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch history as soon as the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutProvider>();
      provider.loadExerciseHistory(widget.exerciseName);
      provider.loadPersonalRecord(widget.exerciseName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exerciseName), centerTitle: true),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.currentLog == null ||
              widget.exerciseIndex >= provider.currentLog!.exercises.length) {
            return const Text('Error loading exercise');
          }
          final WorkoutExercise exercise =
              provider.currentLog!.exercises[widget.exerciseIndex];
          return Column(
            children: [
              Consumer<WorkoutProvider>(
                builder: (context, provider, _) {
                  return HistoryCard(history: provider.lastPerformance);
                },
              ),
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
                    return Dismissible(
                      key: ValueKey(set.id ?? UniqueKey()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        provider.deleteSet(widget.exerciseIndex, index);
                      },
                      child: _SetRow(
                        set: set,
                        setIndex: index,
                        exerciseIndex: widget.exerciseIndex,
                        existingPR: provider.currentPR,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.addSetToExercise(
                            widget.exerciseIndex,
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
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Starts a 90-second rest timer
                          context.read<TimerProvider>().startTimer(90);
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text("90s Rest"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const RestTimerBanner(),
    );
  }
}

// Upgraded to a StatefulWidget to manage local TextFields without losing focus
class _SetRow extends StatefulWidget {
  final ExerciseSet set;
  final int setIndex; // The actual index in the list (0, 1, 2...)
  final int exerciseIndex; // Which exercise this set belongs to
  final double existingPR;

  const _SetRow({
    required this.set,
    required this.setIndex,
    required this.exerciseIndex,
    required this.existingPR,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _rpeController;
  late TextEditingController _rirController;

  // FocusNodes detect when you tap away from a text field
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();
  final FocusNode _rpeFocus = FocusNode();
  final FocusNode _rirFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data (if any)
    _weightController = TextEditingController(
      text: widget.set.weight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps == 0 ? '' : widget.set.reps.toString(),
    );
    _rpeController = TextEditingController(
      text: widget.set.rpe?.toString() ?? '',
    );
    _rirController = TextEditingController(
      text: widget.set.rir?.toString() ?? '',
    );

    _weightController.addListener(() => setState(() {}));
    _repsController.addListener(() => setState(() {}));

    // Add listeners to save data when the user taps outside the text field
    _weightFocus.addListener(_onFocusChange);
    _repsFocus.addListener(_onFocusChange);
    _rpeFocus.addListener(_onFocusChange);
    _rirFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    _rirController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _rpeFocus.dispose();
    _rirFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // If none of the fields have focus, the user is done typing. Save it!
    if (!_weightFocus.hasFocus &&
        !_repsFocus.hasFocus &&
        !_rpeFocus.hasFocus &&
        !_rirFocus.hasFocus) {
      _saveSet();
    }
  }

  void _saveSet() {
    double? weight = double.tryParse(_weightController.text);
    int reps = int.tryParse(_repsController.text) ?? 0;
    double? rpe = double.tryParse(_rpeController.text);
    double? rir = double.tryParse(_rirController.text);

    context.read<WorkoutProvider>().updateSet(
      widget.exerciseIndex,
      widget.setIndex,
      weight,
      reps,
      rpe,
      rir,
    );
  }

  // A helper to create clean, uniform input fields
  Widget _buildTextField(
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (_) =>
              _saveSet(), // Saves when hitting "Done" on keyboard
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double current1RM = 0.0;
    double? weight = double.tryParse(_weightController.text);
    int? reps = int.tryParse(_repsController.text);

    if (weight != null && reps != null) {
      current1RM = OneRepMax.calculate(weight, reps);
    }

    bool isPR = current1RM > widget.existingPR && widget.existingPR > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isPR ? Colors.amber : Colors.blue.shade100,
                child: isPR
                    ? const Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        "${widget.setIndex + 1}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                "${current1RM}kg", // Show raw number
                style: TextStyle(
                  fontSize: 10,
                  // If PR, make text BOLD and AMBER
                  color: isPR ? Colors.amber.shade800 : Colors.grey.shade600,
                  fontWeight: isPR ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _buildTextField(_weightController, _weightFocus, "-"),
          _buildTextField(_repsController, _repsFocus, "-"),
          _buildTextField(_rpeController, _rpeFocus, "-"),
          _buildTextField(_rirController, _rirFocus, "-"),
        ],
      ),
    );
  }
}
