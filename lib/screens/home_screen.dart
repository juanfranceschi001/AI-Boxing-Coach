import 'package:flutter/material.dart';
import '../models/workout_mode.dart';
import 'angle_select_screen.dart';
import 'session_history_screen.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _selectMode(BuildContext context, WorkoutMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AngleSelectScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Boxing Coach')),
      bottomNavigationBar: const BannerAdWidget(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a workout',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final mode in WorkoutMode.values) ...[
              ElevatedButton(
                onPressed: () => _selectMode(context, mode),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                child: Column(
                  children: [
                    Text(mode.label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(mode.description, textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
              ),
              child: const Text('View Workout History'),
            ),
          ],
        ),
      ),
    );
  }
}
