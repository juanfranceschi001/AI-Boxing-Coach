import 'form_issue.dart';
import 'workout_mode.dart';
import 'angle_mode.dart';

/// The outcome of a completed workout, ready for storage/display.
class SessionResult {
  final int? id;
  final DateTime startedAt;
  final Duration duration;
  final WorkoutMode mode;
  final AngleMode angle;
  final int? roundsCompleted;
  final int? punchCount;
  final Map<FormIssueType, int> issueCounts;

  const SessionResult({
    this.id,
    required this.startedAt,
    required this.duration,
    required this.mode,
    required this.angle,
    this.roundsCompleted,
    this.punchCount,
    required this.issueCounts,
  });

  /// Top issues sorted most-frequent first.
  List<MapEntry<FormIssueType, int>> topIssues({int limit = 5}) {
    final entries = issueCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  SessionResult copyWith({int? id}) {
    return SessionResult(
      id: id ?? this.id,
      startedAt: startedAt,
      duration: duration,
      mode: mode,
      angle: angle,
      roundsCompleted: roundsCompleted,
      punchCount: punchCount,
      issueCounts: issueCounts,
    );
  }
}
