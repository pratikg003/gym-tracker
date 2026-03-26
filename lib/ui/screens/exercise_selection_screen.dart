import 'package:flutter/material.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:provider/provider.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  // Removed 'final' so we can add custom exercises to it
  Map<String, List<String>> _exerciseCatalog = {
    'Chest': ['Bench Press', 'Incline Dumbbell Press', 'Cable Fly', 'Push-ups'],
    'Back': ['Pull-ups', 'Lat Pulldown', 'Barbell Row', 'Deadlift'],
    'Legs': ['Squats', 'Leg Press', 'Romanian Deadlift', 'Calf Raises'],
    'Shoulders': ['Overhead Press', 'Lateral Raises', 'Face Pulls'],
    'Biceps': ['Barbell Curl', 'Dumbbell Curl', 'Hammer Curl'],
    'Triceps': ['Tricep Pushdown', 'Overhead Extension', 'Skullcrushers', 'Dips'],
    'Custom': [], // Added a dedicated bucket for uncategorized custom exercises
  };

  final Set<String> _selectedExercises = {};
  String? _activeMuscleGroup; // Tracks which view to show

  // Dialog to create a new custom exercise
  void _showCustomExerciseDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Exercise'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g., Zercher Squat',
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
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  String newExercise = controller.text.trim();
                  // Add to the active muscle group, or 'Custom' if on the grid view
                  String group = _activeMuscleGroup ?? 'Custom';
                  
                  if (!_exerciseCatalog[group]!.contains(newExercise)) {
                    _exerciseCatalog[group]!.add(newExercise);
                  }
                  _selectedExercises.add(newExercise); // Auto-select it
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        // Dynamic Title
        title: Text(_activeMuscleGroup == null ? "Select Muscle" : _activeMuscleGroup!),
        // Dynamic Leading Icon (Back button functionality)
        leading: IconButton(
          icon: Icon(_activeMuscleGroup == null ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_activeMuscleGroup != null) {
              setState(() => _activeMuscleGroup = null); // Go back to grid
            } else {
              Navigator.pop(context); // Close the whole screen
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _showCustomExerciseDialog,
            icon: const Icon(Icons.add_box_outlined),
            tooltip: "Create Custom Exercise",
          ),
        ],
      ),
      body: _activeMuscleGroup == null 
          ? _buildGridView() 
          : _buildListView(provider),

      // Floating Action Button
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, _selectedExercises.toList()),
              label: Text(
                "Add ${_selectedExercises.length} Exercise${_selectedExercises.length > 1 ? 's' : ''}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.check),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- 1. GRID VIEW (Muscle Groups) ---
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: _exerciseCatalog.keys.length,
      itemBuilder: (context, index) {
        String group = _exerciseCatalog.keys.elementAt(index);
        
        // Count how many exercises from this group are currently selected
        int selectedCount = _exerciseCatalog[group]!
            .where((ex) => _selectedExercises.contains(ex))
            .length;

        return InkWell(
          onTap: () => setState(() => _activeMuscleGroup = group),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C), // Dark theme card color
              borderRadius: BorderRadius.circular(16),
              border: selectedCount > 0
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) // Orange accent if items are selected
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    group,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '$selectedCount Selected',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, 
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2. LIST VIEW (Specific Exercises) ---
  Widget _buildListView(WorkoutProvider provider) {
    List<String> exercises = _exerciseCatalog[_activeMuscleGroup!]!;

    if (exercises.isEmpty) {
      return const Center(
        child: Text(
          "No exercises here yet.\nTap the + icon top right to create one.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Padding for the FAB
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        String exercise = exercises[index];
        
        bool alreadyAdded = provider.currentLog?.exercises.any(
              (ex) => ex.exerciseName == exercise,
            ) ?? false;

        bool isSelected = _selectedExercises.contains(exercise);

        return ListTile(
          onTap: alreadyAdded ? null : () {
            setState(() {
              if (isSelected) {
                _selectedExercises.remove(exercise);
              } else {
                _selectedExercises.add(exercise);
              }
            });
          },
          leading: Icon(
            alreadyAdded 
                ? Icons.check_circle 
                : isSelected 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
            color: alreadyAdded 
                ? Colors.grey 
                : isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey,
          ),
          title: Text(
            exercise,
            style: TextStyle(
              color: alreadyAdded ? Colors.grey : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: alreadyAdded
              ? const Text("Already in today's workout", style: TextStyle(color: Colors.grey, fontSize: 12))
              : null,
        );
      },
    );
  }
}