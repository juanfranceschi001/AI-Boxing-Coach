import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/form_issue.dart';
import 'landmark_geometry.dart';
import 'rule_set.dart';

/// Shared form checks applied when the camera is positioned at either side
/// of the boxer. Subclasses (LeftSideRuleSet / RightSideRuleSet) declare
/// which body side faces the camera, since those landmarks are typically
/// more visible/confident than the far side's.
abstract class SideRuleSet implements FormRuleSet {
  PoseLandmarkType get nearShoulder;
  PoseLandmarkType get nearWrist;
  PoseLandmarkType get nearHip;
  PoseLandmarkType get nearKnee;
  PoseLandmarkType get nearAnkle;
  PoseLandmarkType get nearHeel;
  PoseLandmarkType get nearFootIndex;

  // Ratio/angle thresholds are starting points; tune against a real person.
  static const double _guardGapThreshold = 0.15;
  static const double _staggerTooSquareThreshold = 0.3;
  static const double _staggerTooLongThreshold = 1.2;
  static const double _kneeStraightDegrees = 170;
  static const double _leanDegrees = 20;
  // Heel clearly above toe height (on the ball of the foot) vs. flat.
  static const double _heelLiftThreshold = 0.05;
  // Large horizontal heel-to-toe spread means the foot is pointing straight
  // across the frame rather than angled out toward/away from the camera;
  // this doesn't know which foot is lead vs. rear, so it's applied to
  // whichever foot is nearest the camera generally.
  static const double _footStraightThreshold = 0.35;

  @override
  List<FormIssueType> evaluate(Pose pose) {
    final issues = <FormIssueType>[];
    final lm = pose.landmarks;

    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];

    if (!allConfident([leftShoulder, rightShoulder, leftHip, rightHip])) {
      return issues;
    }
    final torso = torsoLength(
        leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torso <= 0) return issues;

    // Stance stagger: horizontal spread between the two feet, regardless of
    // which is forward.
    if (allConfident([leftAnkle, rightAnkle])) {
      final staggerRatio = (leftAnkle!.x - rightAnkle!.x).abs() / torso;
      if (staggerRatio < _staggerTooSquareThreshold) {
        issues.add(FormIssueType.staggerTooSquare);
      } else if (staggerRatio > _staggerTooLongThreshold) {
        issues.add(FormIssueType.staggerTooLong);
      }
    }

    // Knee bend: angle at the near-side knee between hip and ankle.
    final nearHipLm = lm[nearHip];
    final nearKneeLm = lm[nearKnee];
    final nearAnkleLm = lm[nearAnkle];
    if (allConfident([nearHipLm, nearKneeLm, nearAnkleLm])) {
      final kneeAngle = angleAtVertex(
          vecOf(nearKneeLm!), vecOf(nearHipLm!), vecOf(nearAnkleLm!));
      if (kneeAngle > _kneeStraightDegrees) {
        issues.add(FormIssueType.kneesNotBent);
      }
    }

    // Lean/weight balance: torso vector angle from vertical.
    final shoulderMid = midpoint(leftShoulder, rightShoulder);
    final hipMid = midpoint(leftHip, rightHip);
    final leanAngle = angleFromVertical(hipMid, shoulderMid);
    if (leanAngle > _leanDegrees) {
      issues.add(FormIssueType.leaningTooFar);
    }

    // Guard height: near-side (lead) wrist relative to its shoulder.
    final nearShoulderLm = lm[nearShoulder];
    final nearWristLm = lm[nearWrist];
    if (allConfident([nearShoulderLm, nearWristLm])) {
      final guardGap = (nearWristLm!.y - nearShoulderLm!.y) / torso;
      if (guardGap > _guardGapThreshold) {
        issues.add(FormIssueType.handsLow);
      }
    }

    // Chin-tuck heuristic (approximate — see isChinUp doc comment).
    if (isChinUp(pose, torso) == true) {
      issues.add(FormIssueType.chinUp);
    }

    // Heel lift: near-side heel should sit clearly above the toe (on the
    // ball of the foot), not flat.
    final nearHeelLm = lm[nearHeel];
    final nearFootIndexLm = lm[nearFootIndex];
    if (allConfident([nearHeelLm, nearFootIndexLm])) {
      final heelLift = (nearFootIndexLm!.y - nearHeelLm!.y) / torso;
      if (heelLift < _heelLiftThreshold) {
        issues.add(FormIssueType.flatFooted);
      }

      // Foot angle: a large horizontal heel-to-toe spread means the foot
      // points straight across the frame rather than turned out.
      final footSpread = (nearFootIndexLm.x - nearHeelLm.x).abs() / torso;
      if (footSpread > _footStraightThreshold) {
        issues.add(FormIssueType.feetNotAngled);
      }
    }

    return issues;
  }
}
