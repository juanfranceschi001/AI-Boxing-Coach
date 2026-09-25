import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/angle_mode.dart';
import '../models/workout_mode.dart';
import 'live_coaching_screen.dart';
import 'round_config_screen.dart';

class AngleSelectScreen extends StatefulWidget {
  final WorkoutMode mode;

  const AngleSelectScreen({super.key, required this.mode});

  @override
  State<AngleSelectScreen> createState() => _AngleSelectScreenState();
}

class _AngleSelectScreenState extends State<AngleSelectScreen> {
  // Front camera is the common case here: the boxer props the phone up
  // facing themselves rather than needing someone else to aim the back
  // camera at them.
  CameraLensDirection _cameraLens = CameraLensDirection.front;

  void _selectAngle(BuildContext context, AngleMode angle) {
    if (widget.mode == WorkoutMode.roundTimer) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoundConfigScreen(angle: angle, cameraLens: _cameraLens),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveCoachingScreen(
            mode: widget.mode,
            angle: angle,
            cameraLens: _cameraLens,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Angle')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Which camera?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SegmentedButton<CameraLensDirection>(
              segments: const [
                ButtonSegment(
                  value: CameraLensDirection.front,
                  label: Text('Front'),
                  icon: Icon(Icons.camera_front),
                ),
                ButtonSegment(
                  value: CameraLensDirection.back,
                  label: Text('Back'),
                  icon: Icon(Icons.camera_rear),
                ),
              ],
              selected: {_cameraLens},
              onSelectionChanged: (selection) =>
                  setState(() => _cameraLens = selection.first),
            ),
            const SizedBox(height: 32),
            const Text(
              'Where is your phone positioned?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final angle in AngleMode.values) ...[
              ElevatedButton(
                onPressed: () => _selectAngle(context, angle),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                child: Column(
                  children: [
                    Text(angle.label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(angle.description),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
