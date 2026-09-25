import 'package:flutter/material.dart';
import '../data/coach_feedback.dart';
import '../data/tips_repository.dart';
import '../models/form_issue.dart';
import '../models/session_result.dart';
import '../models/workout_mode.dart';
import 'home_screen.dart';
import '../widgets/banner_ad_widget.dart';

class SummaryScreen extends StatelessWidget {
  final SessionResult result;

  const SummaryScreen({super.key, required this.result});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final coachSummary = buildCoachSummary(result);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Summary')),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Duration', value: _formatDuration(result.duration)),
              if (result.mode == WorkoutMode.roundTimer)
                _StatTile(
                    label: 'Rounds', value: '${result.roundsCompleted ?? 0}')
              else
                _StatTile(label: 'Punches', value: '${result.punchCount ?? 0}'),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            coachSummary.improvements.isEmpty
                ? "Great session! Here's the rundown."
                : "Good work out there. Let's go over how it went.",
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 28),
          const Text(
            'What you did well',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (coachSummary.strengths.isEmpty)
            const Text(
              "Nothing stood out as consistently solid yet — that's normal "
              "early on. Focus on the tips below and it'll show up here "
              'next time.',
            )
          else
            for (final strength in coachSummary.strengths)
              _StrengthCard(text: strength),
          const SizedBox(height: 28),
          const Text(
            'What to work on',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (coachSummary.improvements.isEmpty)
            const Text('Nothing major to flag — keep training like that.')
          else
            for (final entry in coachSummary.improvements)
              _IssueCard(type: entry.key, count: entry.value),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final String text;

  const _StrengthCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final FormIssueType type;
  final int count;

  const _IssueCard({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type.cue,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${count}x', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(TipsRepository.tipFor(type)),
          ],
        ),
      ),
    );
  }
}
