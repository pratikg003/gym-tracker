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
  String? _selectedCategory;
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadAllLoggedExercises();
      context.read<WorkoutProvider>().loadWeeklyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    // Grab the most recent weight log, defaulting to 65.0 kg if empty
    final currentWeight = provider.currentLog?.bodyWeight ?? 65.0;

    // Find the all-time highest 1RM for the selected exercise
    double maxLift = 0.0;
    if (provider.progressionHistory.isNotEmpty) {
      maxLift = provider.progressionHistory
          .map((log) => log['max_1rm'] as double)
          .reduce((a, b) => a > b ? a : b);
    }

    // --- SAFE STATE INITIALIZATION ---
    final groupedExercises = provider.loggedExercisesByCategory;

    // 1. Safely initialize category if empty
    if (_selectedCategory == null && groupedExercises.isNotEmpty) {
      _selectedCategory = groupedExercises.keys.first;
    }

    // 2. Safely initialize exercise based on selected category
    List<String> currentExercises = groupedExercises[_selectedCategory] ?? [];
    if (!currentExercises.contains(_selectedExercise) &&
        currentExercises.isNotEmpty) {
      _selectedExercise = currentExercises.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 0. CONSISTENCY TRACKER ---
            Row(
              children: [
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '7-Day Consistency',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${provider.weeklyWorkoutCount}', // <--- WIRED TO PROVIDER
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: 6.0,
                                  left: 6.0,
                                ),
                                child: Text(
                                  'workouts completed',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- 1. BODY WEIGHT SECTION ---
            const Text(
              'Body Weight',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Weight',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            provider.getBodyweightTrend(),
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Plug in your existing chart widget here!
                    const SizedBox(height: 150, child: WeightChart()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. EXERCISE PROGRESS SECTION ---
            const Text(
              'Exercise Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OUTLINED DROPDOWN
                    // --- THE DROPDOWNS ---
                    // 1. MUSCLE GROUP DROPDOWN
                    const Text(
                      'Muscle Group',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2C2C2C),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.orange,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                              // CRITICAL: Reset the exercise selection when the group changes!
                              _selectedExercise = null;
                            });
                          },
                          items: groupedExercises.keys
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. EXERCISE DROPDOWN
                    const Text(
                      'Exercise',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExercise,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2C2C2C),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.orange,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedExercise = newValue;
                            });
                          },
                          // Map over the exercises specific to the chosen category
                          items: currentExercises.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Max Lift',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${maxLift.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            provider.getMaxLiftTrend(),
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Plug in your existing chart widget and pass the selected exercise!
                    SizedBox(
                      height: 150,
                      child: ProgressionChart(
                        exerciseName: _selectedExercise ?? '',
                      ),
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
