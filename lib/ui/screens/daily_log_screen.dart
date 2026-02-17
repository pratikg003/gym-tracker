import 'package:flutter/material.dart';
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
        title: const Text('Gym Tracker'),
        centerTitle: true,
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
                // --- 1. DATE SELECTOR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Date:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(provider.selectedDate),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          provider.loadLogForDate(picked.toString().split(' ')[0]);
                        }
                      },
                      child: Text(
                        provider.selectedDate, 
                        style: const TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // --- 2. BODYWEIGHT INPUT ---
                Row(
                  children: [
                    const Text("Bodyweight (kg):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g., 66.5',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        // Saves the weight to SQLite when you hit 'Done' on the keyboard
                        onSubmitted: (value) {
                          double? weight = double.tryParse(value);
                          if (weight != null) {
                            provider.logBodyWeight(weight);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bodyweight saved!')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text("Exercises", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // --- 3. EXERCISE LIST ---
                Expanded(
                  child: provider.currentLog?.exercises.isEmpty ?? true
                      ? const Center(child: Text("No exercises added yet. Tap + to start."))
                      : ListView.builder(
                          itemCount: provider.currentLog!.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = provider.currentLog!.exercises[index];
                            return Card(
                              child: ListTile(
                                title: Text(exercise.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${exercise.sets.length} sets logged"),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening ${exercise.exerciseName} sets... (Coming Day 63)')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}