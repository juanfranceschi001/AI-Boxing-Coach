import 'package:flutter/material.dart';

/// Shows the running punch count for Free/Shadow mode.
class PunchCounterDisplay extends StatelessWidget {
  final int punchCount;

  const PunchCounterDisplay({super.key, required this.punchCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'PUNCHES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          '$punchCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
