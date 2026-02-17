import 'package:flutter/material.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final Map<String, List<String>> _exerciseCatalog = {
    'Chest': ['Bench Press', 'Incline Dumbbell Press', 'Cable Fly', 'Push-ups'],
    'Triceps': [
      'Tricep Pushdown',
      'Overhead Extension',
      'Skullcrushers',
      'Dips',
    ],
    'Back': ['Pull-ups', 'Lat Pulldown', 'Barbell Row', 'Deadlift'],
    'Biceps': ['Barbell Curl', 'Dumbbell Curl', 'Hammer Curl'],
    'Legs': ['Squats', 'Leg Press', 'Romanian Deadlift', 'Calf Raises'],
    'Shoulders': ['Overhead Press', 'Lateral Raises', 'Face Pulls'],
  };

  final Set<String> _selectedExercises = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Exercises"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _selectedExercises.toList());
            },
            icon: Icon(Icons.check),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _exerciseCatalog.length,
        itemBuilder: (context, index) {
          String muscleGroup = _exerciseCatalog.keys.elementAt(index);
          List<String> exercises = _exerciseCatalog[muscleGroup]!;

          return ExpansionTile(
            title: Text(
              muscleGroup,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: index == 0, // Expand the first one by default
            children: exercises.map((exercise) {
              return CheckboxListTile(
                title: Text(exercise),
                value: _selectedExercises.contains(exercise),
                onChanged: (bool? selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedExercises.add(exercise);
                    } else {
                      _selectedExercises.remove(exercise);
                    }
                  });
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pop(context, _selectedExercises.toList()),
              label: Text("Add ${_selectedExercises.length}"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
