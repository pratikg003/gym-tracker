import 'package:flutter/material.dart';
import 'package:gym_tracker/core/providers/timer_provider.dart';
import 'package:provider/provider.dart';

class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        if (!timer.isRunning) return const SizedBox.shrink();

        return Container(
          color: Colors.blue.shade900,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "Rest: ${timer.formattedTime}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => timer.stopTimer(),
                child: const Text(
                  "SKIP",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
