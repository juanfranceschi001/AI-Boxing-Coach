import '../models/form_issue.dart';

/// Plain-language coaching tips shown on the summary screen, keyed by issue type.
class TipsRepository {
  static const Map<FormIssueType, String> _tips = {
    FormIssueType.handsLow:
        'Your guard dropped frequently. Keep your fists near your cheeks '
            'between punches so you can block or counter instantly.',
    FormIssueType.stanceNarrow:
        'Your feet were too close together, which hurts balance. Widen '
            'your stance to roughly shoulder-width for a stable base.',
    FormIssueType.stanceWide:
        'Your stance was too wide, which slows your movement. Bring your '
            'feet in slightly so you can pivot and step more freely.',
    FormIssueType.elbowsFlared:
        'Your elbows flared out often. Keep them tucked close to your '
            'ribs to protect your body and shorten your punches.',
    FormIssueType.staggerTooSquare:
        'Your feet were too square to the target. Stagger your lead and '
            'rear foot more for better balance and hip rotation.',
    FormIssueType.staggerTooLong:
        'Your stance was overextended front-to-back. Shorten the gap '
            'between your feet so you can move and defend quickly.',
    FormIssueType.kneesNotBent:
        'Your legs were too straight for much of the session. Bend your '
            'knees slightly to absorb movement and generate more power.',
    FormIssueType.leaningTooFar:
        'Your weight shifted too far forward or back at times. Stay '
            "centered over your base so you're not easily pushed off balance.",
    FormIssueType.chinUp:
        'Your chin lifted up often, leaving it exposed. Tuck your chin '
            'toward your chest to protect it.',
    FormIssueType.flatFooted:
        'You spent a lot of time flat-footed. Stay up on the balls of your '
            "feet so you're ready to move in any direction instantly.",
    FormIssueType.feetNotAngled:
        'Your back foot was pointing too straight ahead. Angle it outward '
            '45-90 degrees so you can pivot and generate power more easily.',
  };

  static String tipFor(FormIssueType type) =>
      _tips[type] ?? 'Keep working on this aspect of your form.';
}
