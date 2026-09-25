import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/form_issue.dart';
import 'landmark_geometry.dart';
import 'rule_set.dart';

/// Form checks applied when the camera is positioned in front of the boxer.
class FrontRuleSet implements FormRuleSet {
  // Ratio thresholds are starting points; tune against a real person.
  static const double _guardGapThreshold = 0.15;
  static const double _stanceNarrowThreshold = 0.8;
  static const double _stanceWideThreshold = 1.6;
  static const double _elbowFlareDegrees = 40;

  @override
  List<FormIssueType> evaluate(Pose pose) {
    final issues = <FormIssueType>[];
    final lm = pose.landmarks;

    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final leftWrist = lm[PoseLandmarkType.leftWrist];
    final rightWrist = lm[PoseLandmarkType.rightWrist];
    final leftElbow = lm[PoseLandmarkType.leftElbow];
    final rightElbow = lm[PoseLandmarkType.rightElbow];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];

    if (!allConfident([leftShoulder, rightShoulder, leftHip, rightHip])) {
      return issues;
    }
    final torso = torsoLength(
        leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torso <= 0) return issues;

    // Chin-tuck heuristic (approximate — see isChinUp doc comment).
    if (isChinUp(pose, torso) == true) {
      issues.add(FormIssueType.chinUp);
    }

    // Guard height: either wrist dropping well below its own shoulder.
    if (allConfident([leftWrist, rightWrist])) {
      final leftGap = (leftWrist!.y - leftShoulder.y) / torso;
      final rightGap = (rightWrist!.y - rightShoulder.y) / torso;
      if (leftGap > _guardGapThreshold || rightGap > _guardGapThreshold) {
        issues.add(FormIssueType.handsLow);
      }
    }

    // Stance width relative to shoulder width.
    if (allConfident([leftAnkle, rightAnkle])) {
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final ankleWidth = (leftAnkle!.x - rightAnkle!.x).abs();
      if (shoulderWidth > 0) {
        final stanceRatio = ankleWidth / shoulderWidth;
        if (stanceRatio < _stanceNarrowThreshold) {
          issues.add(FormIssueType.stanceNarrow);
        } else if (stanceRatio > _stanceWideThreshold) {
          issues.add(FormIssueType.stanceWide);
        }
      }
    }

    // Elbow flare: upper-arm angle from vertical, only meaningful with
    // guard roughly up (otherwise a low guard naturally flares the elbow).
    final guardIsUp = !issues.contains(FormIssueType.handsLow);
    if (guardIsUp && allConfident([leftElbow, rightElbow])) {
      final leftFlare =
          angleFromVertical(vecOf(leftShoulder), vecOf(leftElbow!));
      final rightFlare =
          angleFromVertical(vecOf(rightShoulder), vecOf(rightElbow!));
      if (leftFlare > _elbowFlareDegrees || rightFlare > _elbowFlareDegrees) {
        issues.add(FormIssueType.elbowsFlared);
      }
    }

    return issues;
  }
}
