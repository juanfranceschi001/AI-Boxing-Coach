import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/angle_mode.dart';
import '../models/round_config.dart';
import '../models/workout_mode.dart';
import 'live_coaching_screen.dart';

class RoundConfigScreen extends StatefulWidget {
  final AngleMode angle;
  final CameraLensDirection cameraLens;

  const RoundConfigScreen({
    super.key,
    required this.angle,
    this.cameraLens = CameraLensDirection.front,
  });

  @override
  State<RoundConfigScreen> createState() => _RoundConfigScreenState();
}

class _RoundConfigScreenState extends State<RoundConfigScreen> {
  int _roundMinutes = 3;
  int _restSeconds = 60;
  int _numRounds = 3;

  void _start() {
    final config = RoundConfig(
      roundLength: Duration(minutes: _roundMinutes),
      restLength: Duration(seconds: _restSeconds),
      numRounds: _numRounds,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveCoachingScreen(
          mode: WorkoutMode.roundTimer,
          angle: widget.angle,
          roundConfig: config,
          cameraLens: widget.cameraLens,
        ),
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required String valueLabel,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        IconButton(
            onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline)),
        SizedBox(
          width: 64,
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
            onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Round Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepperRow(
              label: 'Round length (min)',
              valueLabel: '$_roundMinutes',
              onDecrement: () => setState(
                  () => _roundMinutes = (_roundMinutes - 1).clamp(1, 10)),
              onIncrement: () => setState(
                  () => _roundMinutes = (_roundMinutes + 1).clamp(1, 10)),
            ),
            const SizedBox(height: 16),
            _stepperRow(
              label: 'Rest length (sec)',
              valueLabel: '$_restSeconds',
              onDecrement: () => setState(
                  () => _restSeconds = (_restSeconds - 15).clamp(15, 300)),
              onIncrement: () => setState(
                  () => _restSeconds = (_restSeconds + 15).clamp(15, 300)),
            ),
            const SizedBox(height: 16),
            _stepperRow(
              label: 'Number of rounds',
              valueLabel: '$_numRounds',
              onDecrement: () =>
                  setState(() => _numRounds = (_numRounds - 1).clamp(1, 20)),
              onIncrement: () =>
                  setState(() => _numRounds = (_numRounds + 1).clamp(1, 20)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(18)),
              child: const Text('Start Workout', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
