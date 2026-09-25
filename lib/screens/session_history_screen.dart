import 'package:flutter/material.dart';
import '../models/session_result.dart';
import '../models/workout_mode.dart';
import '../services/session/session_repository.dart';
import 'summary_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final SessionRepository _repository = SessionRepository();
  late final Future<List<SessionResult>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _repository.loadAll();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: FutureBuilder<List<SessionResult>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) {
            return const Center(child: Text('No workouts yet.'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final subtitleStat = session.mode == WorkoutMode.roundTimer
                  ? '${session.roundsCompleted ?? 0} rounds'
                  : '${session.punchCount ?? 0} punches';
              return ListTile(
                title: Text(
                  '${session.mode.label} • ${session.angle.label}',
                ),
                subtitle: Text(
                  '${session.startedAt.toLocal()} • ${_formatDuration(session.duration)} • $subtitleStat',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SummaryScreen(result: session),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
