import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/providers/workout_provider.dart';

class WeightChart extends StatefulWidget {
  const WeightChart({super.key});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadWeightHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final history = provider.weightHistory;
        
        if (history.isEmpty) {
          return const Center(
            child: Text(
              "Log your weight to see progress.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        List<FlSpot> spots = [];
        double minY = double.infinity;
        double maxY = 0;

        for (int i = 0; i < history.length; i++) {
          double weight = history[i]['body_weight'] as double;
          spots.add(FlSpot(i.toDouble(), weight));
          if (weight < minY) minY = weight;
          if (weight > maxY) maxY = weight;
        }

        // Add padding to Y-axis so the line doesn't touch the top/bottom edges
        minY = (minY - 2).clamp(0, double.infinity);
        maxY = maxY + 2;

        double maxXValue = spots.length > 1 ? (spots.length - 1).toDouble() : 1.0;

        // Return ONLY the LineChart, no background containers or text
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
                  color: Colors.orange.withValues(alpha: 0.1), // Subtle gradient under the line
                ),
              ),
            ],
            titlesData: const FlTitlesData(show: false), // Hide all axis numbers for a clean look
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        );
      },
    );
  }
}