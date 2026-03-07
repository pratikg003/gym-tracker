import 'package:flutter/material.dart';
import 'package:gym_tracker/ui/screens/exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../core/providers/workout_provider.dart';
import 'exercise_selection_screen.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load today's date automatically when the screen opens
    String today = DateTime.now().toString().split(' ')[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadLogForDate(today);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Log'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'save') _showSaveTemplateDialog(context);
              if (value == 'load') _showLoadTemplateSheet(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'load',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Load Routine'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save as Routine'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // FLOATING ACTION BUTTON - Navigates to the multi-select screen
      floatingActionButton: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to the new screen and wait for the result
              final List<String>? selectedExercises = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseSelectionScreen(),
                ),
              );

              // If the user selected exercises and didn't just hit back, save them
              if (selectedExercises != null && selectedExercises.isNotEmpty) {
                provider.addMultipleExercises(selectedExercises);
              }
            },
          );
        },
      ),

      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // If a weight is already saved for this date, populate the text field
          if (provider.currentLog?.bodyWeight != null) {
            _weightController.text = provider.currentLog!.bodyWeight.toString();
          } else {
            _weightController.clear();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const WeightChart(),
                // const SizedBox(height: 24),
                // --- 1. DATE SELECTOR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Date:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(provider.selectedDate),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          provider.loadLogForDate(
                            picked.toString().split(' ')[0],
                          );
                        }
                      },
                      child: Text(
                        provider.selectedDate,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // --- 2. BODYWEIGHT INPUT ---
                Row(
                  children: [
                    const Text(
                      "Bodyweight (kg):",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g., 66.5',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        // Saves the weight to SQLite when you hit 'Done' on the keyboard
                        onSubmitted: (value) {
                          double? weight = double.tryParse(value);
                          if (weight != null) {
                            provider.logBodyWeight(weight);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bodyweight saved!'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // --- 3. REST DAY TOGGLE ---
                if (provider.currentLog != null)
                  Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ), // Removed horizontal margin to align with padding
                    child: SwitchListTile(
                      title: const Text(
                        'Mark as Rest Day',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Take a break and recover.'),
                      secondary: const Icon(
                        Icons.airline_seat_individual_suite,
                        color: Colors.blue,
                      ),
                      value: provider.currentLog!.isRestDay,
                      onChanged: (bool value) {
                        provider.toggleRestDay(value);
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // --- 4. EXERCISE LIST OR REST DAY MESSAGE ---
                if (provider.currentLog != null &&
                    provider.currentLog!.isRestDay)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Enjoy your rest day! 🛑",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 32),
                  const Text(
                    "Exercises",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // --- 3. EXERCISE LIST ---
                  Expanded(
                    child: provider.currentLog?.exercises.isEmpty ?? true
                        ? const Center(
                            child: Text(
                              "No exercises added yet. Tap + to start.",
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.currentLog!.exercises.length,
                            itemBuilder: (context, index) {
                              final exercise =
                                  provider.currentLog!.exercises[index];
                              return Dismissible(
                                key: ValueKey(exercise.id ?? UniqueKey()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  provider.deleteExercise(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${exercise.exerciseName} deleted!',
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      exercise.exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${exercise.sets.length} sets logged",
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExerciseDetailScreen(
                                            exerciseIndex:
                                                index, // Pass the index, not the object!
                                            exerciseName: exercise
                                                .exerciseName, // Pass name for the AppBar
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 1. Show Dialog to Name and Save the Routine
  void _showSaveTemplateDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Routine'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Push Day, Upper Body...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<WorkoutProvider>().saveCurrentAsTemplate(
                  nameController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Routine "${nameController.text.trim()}" saved!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // 2. Show Bottom Sheet to Select and Load a Routine
  void _showLoadTemplateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<WorkoutProvider>(
          builder: (context, provider, child) {
            if (provider.templates.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "No routines saved yet.\nAdd exercises to your day and tap 'Save as Routine'.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Load Routine",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.templates.length,
                    itemBuilder: (context, index) {
                      final template = provider.templates[index];
                      return ListTile(
                        leading: const Icon(Icons.list_alt, color: Colors.blue),
                        title: Text(
                          template['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              provider.removeTemplate(template['id']),
                        ),
                        onTap: () {
                          provider.applyTemplate(template['id']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
