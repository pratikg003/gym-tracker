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
          return const SizedBox(
            height: 200, 
            width: double.infinity,
            child: Center(child: Text("Log your weight to see progress."))
          );
        }

        // Convert SQLite data into FlSpot coordinates
        List<FlSpot> spots = [];
        for (int i = 0; i < history.length; i++) {
          spots.add(FlSpot(i.toDouble(), history[i]['body_weight'] as double));
        }

        // CRITICAL FIX: Prevent division by zero if there is only 1 data point
        double maxXValue = spots.length > 1 ? (spots.length - 1).toDouble() : 1.0;

        return SizedBox(
          height: 250,
          width: double.infinity, // Safe to use here inside a SizedBox
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bodyweight Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: 0.0,
                      maxX: maxXValue, // Enforces a valid chart width constraint
                      minY: 60.0,
                      maxY: 75.0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
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