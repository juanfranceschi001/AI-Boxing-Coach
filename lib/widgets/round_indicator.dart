import 'package:flutter/material.dart';
import '../services/session/round_timer_controller.dart';

/// Shows current round number and a countdown for Round Timer mode.
class RoundIndicator extends StatelessWidget {
  final RoundTimerController controller;
  final int totalRounds;

  const RoundIndicator({
    super.key,
    required this.controller,
    required this.totalRounds,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isRest = controller.phase == RoundPhase.rest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isRest
              ? 'REST'
              : 'ROUND ${controller.currentRound} / $totalRounds',
          style: TextStyle(
            color: isRest ? Colors.orangeAccent : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          _formatDuration(controller.remaining),
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
