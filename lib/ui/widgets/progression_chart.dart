import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/providers/workout_provider.dart';

class ProgressionChart extends StatefulWidget {
  final String exerciseName; // Now receives this from DashboardScreen

  const ProgressionChart({super.key, required this.exerciseName});

  @override
  State<ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<ProgressionChart> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // This ensures the chart updates when the user changes the dropdown in the Dashboard!
  @override
  void didUpdateWidget(ProgressionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _fetchData();
    }
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadProgressionHistory(widget.exerciseName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final history = provider.progressionHistory;

        if (history.isEmpty) {
          return const Center(
            child: Text(
              "No data for this exercise yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        List<FlSpot> spots = [];
        double minY = double.infinity;
        double maxY = 0;

        for (int i = 0; i < history.length; i++) {
          double weight = history[i]['max_1rm'] as double;
          spots.add(FlSpot(i.toDouble(), weight));
          if (weight < minY) minY = weight;
          if (weight > maxY) maxY = weight;
        }

        minY = (minY - 10).clamp(0, double.infinity);
        maxY = maxY + 10;
        double maxXValue = spots.length > 1 ? (spots.length - 1).toDouble() : 1.0;

        return LineChart(
          LineChartData(
            minX: 0.0,
            maxX: maxXValue,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.orange, // Matched to theme
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF1E1E1E),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orange.withOpacity(0.1),
                ),
              ),
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        );
      },
    );
  }
}