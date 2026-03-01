import 'package:flutter/material.dart';
import 'package:gym_tracker/ui/widgets/progression_chart.dart';
import '../widgets/weight_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeightChart(),
            SizedBox(height: 24,),
            ProgressionChart(),
          ],
        ),
      ),
    );
  }
}