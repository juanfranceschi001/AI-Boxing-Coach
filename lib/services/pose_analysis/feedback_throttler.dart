import 'dart:collection';
import '../../models/form_issue.dart';

/// Result of feeding one frame's detected issues through [FeedbackThrottler].
class FrameFeedbackResult {
  /// Issues that have appeared consistently enough across the recent frame
  /// window to be considered "really happening" (debounced). Suitable for
  /// driving the on-screen banner, which can update more responsively than
  /// spoken cues.
  final List<FormIssueType> activeIssues;

  /// Subset of [activeIssues] whose per-issue cooldown has expired this
  /// frame — these should trigger a spoken cue and count as one occurrence
  /// toward the session's issue-frequency summary.
  final List<FormIssueType> cueIssues;

  const FrameFeedbackResult(
      {required this.activeIssues, required this.cueIssues});
}

/// Smooths raw per-frame pose-analysis output into stable, non-spammy
/// feedback events.
///
/// Two mechanisms combine:
///  - A sliding-window debounce: an issue must appear in at least
///    [minHitsInWindow] of the last [windowSize] analyzed frames before it's
///    considered real (filters single-frame pose jitter/noise).
///  - A per-issue cooldown: once cued, the same issue won't cue again until
///    [cooldown] has elapsed, so a sustained problem doesn't spam the user.
class FeedbackThrottler {
  final Duration cooldown;
  final int windowSize;
  final int minHitsInWindow;

  final Queue<Set<FormIssueType>> _window = Queue();
  final Map<FormIssueType, DateTime> _lastCueTime = {};

  FeedbackThrottler({
    this.cooldown = const Duration(seconds: 5),
    this.windowSize = 8,
    this.minHitsInWindow = 5,
  });

  FrameFeedbackResult process(List<FormIssueType> detectedThisFrame,
      {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    _window.addLast(detectedThisFrame.toSet());
    while (_window.length > windowSize) {
      _window.removeFirst();
    }

    final counts = <FormIssueType, int>{};
    for (final frameSet in _window) {
      for (final issue in frameSet) {
        counts[issue] = (counts[issue] ?? 0) + 1;
      }
    }

    final active = <FormIssueType>[
      for (final entry in counts.entries)
        if (entry.value >= minHitsInWindow) entry.key,
    ];

    final cueIssues = <FormIssueType>[];
    for (final issue in active) {
      final last = _lastCueTime[issue];
      if (last == null || currentTime.difference(last) >= cooldown) {
        cueIssues.add(issue);
        _lastCueTime[issue] = currentTime;
      }
    }

    return FrameFeedbackResult(activeIssues: active, cueIssues: cueIssues);
  }

  void reset() {
    _window.clear();
    _lastCueTime.clear();
  }
}
