import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'side_rule_set.dart';

/// Used when the camera is positioned at the boxer's left side.
class LeftSideRuleSet extends SideRuleSet {
  @override
  PoseLandmarkType get nearShoulder => PoseLandmarkType.leftShoulder;
  @override
  PoseLandmarkType get nearWrist => PoseLandmarkType.leftWrist;
  @override
  PoseLandmarkType get nearHip => PoseLandmarkType.leftHip;
  @override
  PoseLandmarkType get nearKnee => PoseLandmarkType.leftKnee;
  @override
  PoseLandmarkType get nearAnkle => PoseLandmarkType.leftAnkle;
  @override
  PoseLandmarkType get nearHeel => PoseLandmarkType.leftHeel;
  @override
  PoseLandmarkType get nearFootIndex => PoseLandmarkType.leftFootIndex;
}
