import 'package:flutter/material.dart';
import 'package:gym_tracker/ui/widgets/exercise_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/workout_provider.dart';
import 'exercise_selection_screen.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  // final TextEditingController _weightController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    // Load today's date automatically when the screen opens
    String today = DateTime.now().toString().split(' ')[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadLogForDate(today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FLOATING ACTION BUTTON
      floatingActionButton: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final List<String>? selectedExercises = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseSelectionScreen(),
                ),
              );

              if (selectedExercises != null && selectedExercises.isNotEmpty) {
                provider.addMultipleExercises(selectedExercises);
              }
            },
          );
        },
      ),

      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Added SafeArea because we removed the App Bar
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // --- 1. CALENDAR & REST DAY TOGGLE ---
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CALENDAR QUICK SELECTOR
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E), // Darker header background
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(
                              32,
                            ), // High-radius curve on the bottom
                          ),
                        ),
                        // Stack allows us to place the menu button over the calendar
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                TableCalendar(
                                  focusedDay: DateTime.parse(
                                    provider.selectedDate,
                                  ),
                                  firstDay: DateTime(2020),
                                  lastDay: DateTime.now(),

                                  calendarFormat: _calendarFormat,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Month',
                                    CalendarFormat.week: 'Week',
                                  },
                                  onFormatChanged: (format) {
                                    if (_calendarFormat != format) {
                                      setState(() {
                                        _calendarFormat = format;
                                      });
                                    }
                                  },
                                  selectedDayPredicate: (day) {
                                    return isSameDay(
                                      DateTime.parse(provider.selectedDate),
                                      day,
                                    );
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
                                    provider.loadLogForDate(
                                      selectedDay.toString().split(' ')[0],
                                    );
                                  },
                                  headerVisible: true,
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered:
                                        false, // <-- Moves the Month to the left
                                    titleTextStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    leftChevronIcon: Icon(
                                      Icons.chevron_left,
                                      color: Colors.orange,
                                    ),
                                    rightChevronIcon: Icon(
                                      Icons.chevron_right,
                                      color: Colors.orange,
                                    ),
                                    rightChevronMargin: EdgeInsets.only(
                                      right: 40,
                                    ), // <-- Shifts right arrow over to make room for menu
                                  ),
                                  calendarStyle: CalendarStyle(
                                    isTodayHighlighted: true,
                                    todayDecoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    defaultTextStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    weekendTextStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    outsideDaysVisible: false,
                                  ),
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    weekendStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // --- THE MENU BUTTON INSIDE THE CARD ---
                                Positioned(
                                  top: 4,
                                  right: 0,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                    ),
                                    color: const Color(
                                      0xFF2C2C2C,
                                    ), // Dark theme dropdown
                                    onSelected: (value) {
                                      if (value == 'save') {
                                        _showSaveTemplateDialog(context);
                                      }
                                      if (value == 'load') {
                                        _showLoadTemplateSheet(context);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'load',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.download,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Load Routine',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'save',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.save,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Save as Routine',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _calendarFormat == CalendarFormat.month
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // REST DAY TOGGLE
                      if (provider.currentLog != null &&
                          provider.currentLog!.exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16,0,16,16),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: SwitchListTile(
                              title: const Text(
                                'Mark as Rest Day',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Take a break and recover.'),
                              secondary: const Icon(
                                Icons.airline_seat_individual_suite,
                                color: Colors.orange,
                              ),
                              value: provider.currentLog!.isRestDay,
                              onChanged: (bool value) {
                                provider.toggleRestDay(value);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // --- 2. EXERCISE LIST ---
                if (provider.currentLog != null &&
                    provider.currentLog!.isRestDay)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "Enjoy your rest day! 🛑",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  )
                else if (provider.currentLog?.exercises.isEmpty ?? true)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "No exercises added yet. Tap + to start.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ExerciseCard(
                          exercise: provider.currentLog!.exercises[index],
                          exerciseIndex: index,
                        );
                      }, childCount: provider.currentLog!.exercises.length),
                    ),
                  ),

                // Add bottom padding so the FAB doesn't cover the last card
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1. Show Dialog to Name and Save the Routine
  void _showSaveTemplateDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Routine'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Push Day, Upper Body...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<WorkoutProvider>().saveCurrentAsTemplate(
                  nameController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Routine "${nameController.text.trim()}" saved!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // 2. Show Bottom Sheet to Select and Load a Routine
  void _showLoadTemplateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<WorkoutProvider>(
          builder: (context, provider, child) {
            if (provider.templates.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "No routines saved yet.\nAdd exercises to your day and tap 'Save as Routine'.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Load Routine",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.templates.length,
                    itemBuilder: (context, index) {
                      final template = provider.templates[index];
                      return ListTile(
                        leading: const Icon(Icons.list_alt, color: Colors.blue),
                        title: Text(
                          template['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              provider.removeTemplate(template['id']),
                        ),
                        onTap: () {
                          provider.applyTemplate(template['id']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
