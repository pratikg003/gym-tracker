import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_tracker/core/database/database_helper.dart';
import 'package:gym_tracker/core/providers/timer_provider.dart';
import 'package:gym_tracker/core/providers/workout_provider.dart';
import 'package:gym_tracker/ui/screens/main_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkoutProvider()),
        ChangeNotifierProvider(create: (context) => TimerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    const Color highVisOrange = Color(0xFFFF6D00);
    return MaterialApp(
      title: 'Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: highVisOrange,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: highVisOrange,
          brightness: Brightness.dark,
          primary: highVisOrange,
          secondary: highVisOrange,

          surface: const Color(0xFF121212),
        ),

        scaffoldBackgroundColor: const Color(0xFF121212),

        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: highVisOrange),
        ),
      ),

      themeMode: ThemeMode.dark,
      home: const MainScreen(),
    );
  }
}
