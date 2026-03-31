import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:gym_tracker/ui/widgets/weight_chart.dart';
import 'package:gym_tracker/ui/widgets/progression_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Default to a common exercise, we will make this dynamic later based on DB
  String? _selectedExercise = 'Bench Press'; 

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    
    // Grab the most recent weight log, defaulting to 65.0 kg if empty
    final currentWeight = provider.currentLog?.bodyWeight ?? 65.0; 
    
    // Placeholder for max lift (we will wire this to a provider method later)
    final double maxLift = 100.0; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. BODY WEIGHT SECTION ---
            const Text(
              'Body Weight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Weight', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '↑ 1.2 kg', // TODO: Calculate diff from last week
                            style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Plug in your existing chart widget here!
                    const SizedBox(
                      height: 150,
                      child: WeightChart(), 
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // --- 2. EXERCISE PROGRESS SECTION ---
            const Text(
              'Exercise Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OUTLINED DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1), // Orange accent border
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExercise,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2C2C2C),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedExercise = newValue;
                            });
                          },
                          // TODO: Replace with provider.getAllLoggedExercises()
                          items: <String>['Bench Press', 'Squats', 'Barbell Row', 'Deadlift'] 
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Max Lift', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${maxLift.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '↑ 2.5 kg', // TODO: Calculate diff from last 1RM
                            style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Plug in your existing chart widget and pass the selected exercise!
                    SizedBox(
                      height: 150,
                      child: ProgressionChart(exerciseName: _selectedExercise ?? ''), 
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }
}