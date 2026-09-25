import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'landmark_geometry.dart';

class _ArmState {
  bool sawExtension = false;
  DateTime? lastPunchTime;
}

/// Estimates punches thrown from wrist-to-shoulder distance over time,
/// since Free/Shadow mode has no round timer or external rep source.
///
/// Uses simple hysteresis: once an arm's wrist-to-shoulder ratio crosses
/// above [_extendedThreshold], the next time it drops back below the lower
/// [_retractingStartThreshold] counts as one punch. This deliberately does
/// NOT require returning all the way to a fully "retracted" resting
/// position first — an earlier version did, which undercounted fast combos
/// where the next punch starts before the arm has fully come back home.
/// It also doesn't require reaching a near-full-extension ratio, so hooks
/// and other punches that don't fully straighten the arm still register.
///
/// Distance uses ML Kit's 3D landmark position (x, y, and z/depth), not
/// just the 2D image position. This matters a lot for the common setup of
/// a front-facing camera with the boxer punching straight at it/the
/// mirror: a jab or cross thrown that way moves mostly along the camera's
/// depth axis and barely shifts in 2D (x, y), so a 2D-only distance badly
/// undercounts punches in that very common configuration.
class PunchCounter {
  // Ratios are normalized against torso length (shoulder-to-hip distance).
  static const double _extendedThreshold = 0.65;
  static const double _retractingStartThreshold = 0.5;
  static const Duration _refractoryPeriod = Duration(milliseconds: 200);
  // Fast punches motion-blur the wrist, dropping ML Kit's confidence for it
  // right at the moment (near full extension) we most need to sample it —
  // trust it at a lower bar than the default body-joint confidence.
  static const double _wristMinLikelihood = 0.35;

  final _ArmState _left = _ArmState();
  final _ArmState _right = _ArmState();

  int leftCount = 0;
  int rightCount = 0;
  int get totalCount => leftCount + rightCount;

  /// Feed one analyzed frame. Returns how many punches were just registered
  /// (0, 1, or 2 if both arms completed a cycle on the same frame).
  int update(Pose pose, DateTime now) {
    final lm = pose.landmarks;
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final leftWrist = lm[PoseLandmarkType.leftWrist];
    final rightWrist = lm[PoseLandmarkType.rightWrist];

    if (!allConfident([leftShoulder, rightShoulder, leftHip, rightHip])) {
      return 0;
    }
    final torso =
        torsoLength(leftShoulder!, rightShoulder!, leftHip!, rightHip!);
    if (torso <= 0) return 0;

    var punches = 0;

    if (allConfident([leftWrist], minLikelihood: _wristMinLikelihood)) {
      final ratio = distance3D(leftWrist!, leftShoulder) / torso;
      if (_stepArm(_left, ratio, now)) {
        leftCount++;
        punches++;
      }
    }

    if (allConfident([rightWrist], minLikelihood: _wristMinLikelihood)) {
      final ratio = distance3D(rightWrist!, rightShoulder) / torso;
      if (_stepArm(_right, ratio, now)) {
        rightCount++;
        punches++;
      }
    }

    return punches;
  }

  /// Advances one arm's hysteresis state by one sample. Returns true if a
  /// punch was just completed (the falling-edge crossing).
  bool _stepArm(_ArmState arm, double ratio, DateTime now) {
    if (!arm.sawExtension) {
      if (ratio >= _extendedThreshold) {
        arm.sawExtension = true;
      }
      return false;
    }

    if (ratio <= _retractingStartThreshold) {
      arm.sawExtension = false;
      final pastRefractory = arm.lastPunchTime == null ||
          now.difference(arm.lastPunchTime!) >= _refractoryPeriod;
      if (pastRefractory) {
        arm.lastPunchTime = now;
        return true;
      }
    }
    return false;
  }

  void reset() {
    leftCount = 0;
    rightCount = 0;
    _left
      ..sawExtension = false
      ..lastPunchTime = null;
    _right
      ..sawExtension = false
      ..lastPunchTime = null;
  }
}
