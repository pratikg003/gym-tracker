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
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                String newExercise = controller.text.trim();
                String group = _activeMuscleGroup ?? 'Custom';

                // 1. Save it permanently via the provider
                await context.read<WorkoutProvider>().createCustomExercise(
                  newExercise,
                  group,
                );

                // 2. Auto-select it so it gets added to today's workout
                setState(() {
                  _selectedExercises.add(newExercise);
                });

                // 3. Close the dialog
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String exerciseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Delete Exercise?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$exerciseName" from your catalog?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<WorkoutProvider>().deleteCustomExercise(
                exerciseName,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        title: Text(
          _activeMuscleGroup == null ? "Select Muscle" : _activeMuscleGroup!,
        ),
        // Dynamic Leading Icon (Back button functionality)
        leading: IconButton(
          icon: Icon(
            _activeMuscleGroup == null ? Icons.close : Icons.arrow_back,
          ),
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
              onPressed: () =>
                  Navigator.pop(context, _selectedExercises.toList()),
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
    final catalog = context.watch<WorkoutProvider>().exerciseCatalog;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: catalog.keys.length,
      itemBuilder: (context, index) {
        String group = catalog.keys.elementAt(index);

        // Count how many exercises from this group are currently selected
        int selectedCount = catalog[group]!
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
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ) // Orange accent if items are selected
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
    final catalog = context.watch<WorkoutProvider>().exerciseCatalog;

    List<String> exercises = catalog[_activeMuscleGroup] ?? [];

    if (exercises.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No exercises found.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to create a new one!',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Padding for the FAB
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        String exercise = exercises[index];

        bool alreadyAdded =
            provider.currentLog?.exercises.any(
              (ex) => ex.exerciseName == exercise,
            ) ??
            false;

        bool isSelected = _selectedExercises.contains(exercise);

        return ListTile(
          onLongPress: () => _showDeleteDialog(context, exercise),
          onTap: alreadyAdded
              ? null
              : () {
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
              ? const Text(
                  "Already in today's workout",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              : null,
        );
      },
    );
  }
}
