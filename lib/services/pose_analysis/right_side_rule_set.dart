import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'side_rule_set.dart';

/// Used when the camera is positioned at the boxer's right side.
class RightSideRuleSet extends SideRuleSet {
  @override
  PoseLandmarkType get nearShoulder => PoseLandmarkType.rightShoulder;
  @override
  PoseLandmarkType get nearWrist => PoseLandmarkType.rightWrist;
  @override
  PoseLandmarkType get nearHip => PoseLandmarkType.rightHip;
  @override
  PoseLandmarkType get nearKnee => PoseLandmarkType.rightKnee;
  @override
  PoseLandmarkType get nearAnkle => PoseLandmarkType.rightAnkle;
  @override
  PoseLandmarkType get nearHeel => PoseLandmarkType.rightHeel;
  @override
  PoseLandmarkType get nearFootIndex => PoseLandmarkType.rightFootIndex;
}
