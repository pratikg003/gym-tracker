import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/database_helper.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  await DatabaseHelper.instance.database;
  print("Database initialized successfully!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Tracker',
      home: const Scaffold(),
    );
  }
}