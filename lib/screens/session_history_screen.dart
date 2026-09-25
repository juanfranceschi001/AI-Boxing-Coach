import 'package:flutter/material.dart';
import '../models/session_result.dart';
import '../models/workout_mode.dart';
import '../services/session/session_repository.dart';
import 'summary_screen.dart';
import '../widgets/banner_ad_widget.dart';

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

  /// e.g. "Thu, Sep 24, 10:16 PM" -- follows the device locale and its
  /// 12/24-hour setting.
  String _formatStartedAt(BuildContext context, DateTime startedAt) {
    final local = startedAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(local);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date, $time';
  }

  String _plural(int count, String noun) =>
      '$count ${count == 1 ? noun : '${noun}s'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      bottomNavigationBar: const BannerAdWidget(),
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
                  ? _plural(session.roundsCompleted ?? 0, 'round')
                  : '${session.punchCount ?? 0} ${session.punchCount == 1 ? 'punch' : 'punches'}';
              return ListTile(
                title: Text(
                  '${session.mode.label} • ${session.angle.label}',
                ),
                subtitle: Text(
                  '${_formatStartedAt(context, session.startedAt)} • ${_formatDuration(session.duration)} • $subtitleStat',
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
