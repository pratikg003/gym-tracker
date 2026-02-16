import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/database_helper.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:gym_tracker/ui/screens/daily_log_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DailyLogScreen(),
    );
  }
}
