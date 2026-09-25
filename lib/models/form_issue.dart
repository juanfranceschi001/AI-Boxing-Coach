/// The kinds of form corrections the coach can detect.
enum FormIssueType {
  handsLow,
  stanceNarrow,
  stanceWide,
  elbowsFlared,
  staggerTooSquare,
  staggerTooLong,
  kneesNotBent,
  leaningTooFar,
  chinUp,
  flatFooted,
  feetNotAngled,
}

extension FormIssueTypeCue on FormIssueType {
  /// Short spoken/on-screen coaching cue.
  String get cue {
    switch (this) {
      case FormIssueType.handsLow:
        return 'Hands up';
      case FormIssueType.stanceNarrow:
        return 'Widen your stance';
      case FormIssueType.stanceWide:
        return 'Narrow your stance';
      case FormIssueType.elbowsFlared:
        return 'Tuck your elbows in';
      case FormIssueType.staggerTooSquare:
        return 'Stagger your stance more';
      case FormIssueType.staggerTooLong:
        return 'Shorten your stance';
      case FormIssueType.kneesNotBent:
        return 'Bend your knees';
      case FormIssueType.leaningTooFar:
        return 'Balance your weight';
      case FormIssueType.chinUp:
        return 'Chin down';
      case FormIssueType.flatFooted:
        return 'Stay on the balls of your feet';
      case FormIssueType.feetNotAngled:
        return 'Angle your back foot outward';
    }
  }
}

/// A single detected correction event during a session.
class FormIssue {
  final FormIssueType type;
  final DateTime timestamp;

  const FormIssue(this.type, this.timestamp);
}
