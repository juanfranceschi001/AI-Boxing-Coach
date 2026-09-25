import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/form_issue.dart';

/// A strategy for turning one detected [Pose] into a list of form issues.
/// Which concrete rule set is active depends on which side of the boxer the
/// camera is positioned at (see AngleMode / FrontRuleSet / LeftSideRuleSet /
/// RightSideRuleSet).
abstract class FormRuleSet {
  List<FormIssueType> evaluate(Pose pose);
}
