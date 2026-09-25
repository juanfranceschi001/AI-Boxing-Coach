import '../models/angle_mode.dart';
import '../models/form_issue.dart';
import '../models/session_result.dart';

/// One aspect of form the coach can praise when it went well. The failure
/// side of the same aspect is whatever already shows up in issueCounts —
/// a topic counts as a strength when none of its failure types fired at
/// all during a session where the check was actually relevant (i.e. the
/// angle used actually evaluates it).
class _CheckTopic {
  final List<FormIssueType> failureTypes;
  final String praise;
  final Set<AngleMode> applicableAngles;

  const _CheckTopic({
    required this.failureTypes,
    required this.praise,
    required this.applicableAngles,
  });
}

const _sideAngles = {AngleMode.leftSide, AngleMode.rightSide};
const _allAngles = {AngleMode.front, AngleMode.leftSide, AngleMode.rightSide};

const List<_CheckTopic> _topics = [
  _CheckTopic(
    failureTypes: [FormIssueType.handsLow],
    praise: 'Your guard stayed up the whole session — hands were right '
        'where they needed to be.',
    applicableAngles: _allAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.stanceNarrow, FormIssueType.stanceWide],
    praise: 'Your stance width was right on — a solid, balanced base '
        'throughout.',
    applicableAngles: {AngleMode.front},
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.elbowsFlared],
    praise: 'You kept your elbows tucked in tight, protecting your body '
        'well.',
    applicableAngles: {AngleMode.front},
  ),
  _CheckTopic(
    failureTypes: [
      FormIssueType.staggerTooSquare,
      FormIssueType.staggerTooLong,
    ],
    praise: 'Your foot stagger looked great — good spacing for power and '
        'mobility.',
    applicableAngles: _sideAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.kneesNotBent],
    praise: 'You kept a nice bend in your knees the whole time, ready to '
        'explode.',
    applicableAngles: _sideAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.leaningTooFar],
    praise: 'You stayed centered over your base instead of leaning too far '
        '— nice balance.',
    applicableAngles: _sideAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.chinUp],
    praise: 'You kept your chin tucked and protected all session. That\'s '
        'real defensive discipline.',
    applicableAngles: _allAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.flatFooted],
    praise: 'You stayed light on your feet — up on the balls of your feet '
        'like you should be.',
    applicableAngles: _sideAngles,
  ),
  _CheckTopic(
    failureTypes: [FormIssueType.feetNotAngled],
    praise: 'Your back foot angle looked good, ready to pivot at any '
        'moment.',
    applicableAngles: _sideAngles,
  ),
];

/// Coach-style debrief built from a completed session: what went well
/// (checks that applied to this session's angle and never tripped) and
/// what to work on (the existing issue-frequency breakdown).
class CoachSummary {
  final List<String> strengths;
  final List<MapEntry<FormIssueType, int>> improvements;

  const CoachSummary({required this.strengths, required this.improvements});
}

CoachSummary buildCoachSummary(SessionResult result) {
  final strengths = <String>[
    for (final topic in _topics)
      if (topic.applicableAngles.contains(result.angle) &&
          topic.failureTypes.every((t) => (result.issueCounts[t] ?? 0) == 0))
        topic.praise,
  ];
  return CoachSummary(strengths: strengths, improvements: result.topIssues());
}
