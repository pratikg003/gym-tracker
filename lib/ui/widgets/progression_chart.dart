import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/providers/workout_provider.dart';

class ProgressionChart extends StatefulWidget {
  const ProgressionChart({super.key});

  @override
  State<ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<ProgressionChart> {
  // Default to Bench Press, but you can change this list
  String _selectedExercise = "Bench Press";
  final List<String> _trackableExercises = [
    "Bench Press",
    "Squat",
    "Deadlift",
    "Overhead Press",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadProgressionHistory(_selectedExercise);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final history = provider.progressionHistory;

        List<FlSpot> spots = [];
        double minY = 0;
        double maxY = 100;

        if (history.isNotEmpty) {
          for (int i = 0; i < history.length; i++) {
            spots.add(FlSpot(i.toDouble(), history[i]['max_1rm'] as double));
          }
          // Dynamic Y-axis based on data
          double maxWeight = spots
              .map((s) => s.y)
              .reduce((a, b) => a > b ? a : b);
          double minWeight = spots
              .map((s) => s.y)
              .reduce((a, b) => a < b ? a : b);
          minY = (minWeight - 10).clamp(0, double.infinity);
          maxY = maxWeight + 10;
        }

        double maxXValue = spots.length > 1
            ? (spots.length - 1).toDouble()
            : 1.0;

        return SizedBox(
          width: double.infinity,
          height: 300,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Strength (1RM)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedExercise,
                      isDense: true,
                      underline: const SizedBox(),
                      items: _trackableExercises.map((String ex) {
                        return DropdownMenuItem<String>(
                          value: ex,
                          child: Text(ex),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedExercise = newValue);
                          provider.loadProgressionHistory(newValue);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text("No data for this exercise yet."),
                        )
                      : LineChart(
                          LineChartData(
                            minX: 0.0,
                            maxX: maxXValue,
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.amber.shade700,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                            titlesData: const FlTitlesData(
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
