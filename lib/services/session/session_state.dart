import 'package:flutter/foundation.dart';
import '../../models/angle_mode.dart';
import '../../models/form_issue.dart';
import '../../models/session_result.dart';
import '../../models/workout_mode.dart';

/// Live, observable state for one in-progress coaching session. The
/// pose-analysis pipeline and round timer feed updates into this; screens
/// (live coaching banner, punch counter, round indicator) read from it via
/// Provider.
class SessionState extends ChangeNotifier {
  final WorkoutMode mode;
  final AngleMode angle;

  DateTime? startedAt;
  Duration elapsed = Duration.zero;
  int punchCount = 0;
  int currentRound = 0;
  final Map<FormIssueType, int> issueCounts = {};
  List<FormIssueType> activeIssues = const [];

  SessionState({required this.mode, required this.angle});

  void start() {
    startedAt = DateTime.now();
    notifyListeners();
  }

  void updateElapsed(Duration value) {
    elapsed = value;
    notifyListeners();
  }

  void updateCurrentRound(int round) {
    currentRound = round;
    notifyListeners();
  }

  void setActiveIssues(List<FormIssueType> issues) {
    activeIssues = issues;
    notifyListeners();
  }

  /// Records that [issue] just triggered a cue (spoken + counted), i.e. one
  /// occurrence toward the session's end-of-summary breakdown.
  void registerCue(FormIssueType issue) {
    issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
  }

  void addPunches(int count) {
    if (count <= 0) return;
    punchCount += count;
    notifyListeners();
  }

  SessionResult buildResult({int? roundsCompleted}) {
    return SessionResult(
      startedAt: startedAt ?? DateTime.now(),
      duration: elapsed,
      mode: mode,
      angle: angle,
      roundsCompleted: roundsCompleted,
      punchCount: mode == WorkoutMode.freeShadow ? punchCount : null,
      issueCounts: Map.of(issueCounts),
    );
  }
}
