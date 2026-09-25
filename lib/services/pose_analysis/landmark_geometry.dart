import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Minimum per-landmark confidence required before a rule trusts it.
const double kMinLikelihood = 0.5;

/// A simple 2D point used for geometry math, decoupled from PoseLandmark.
class Vec2 {
  final double x;
  final double y;
  const Vec2(this.x, this.y);

  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 scaled(double f) => Vec2(x * f, y * f);
}

Vec2 vecOf(PoseLandmark landmark) => Vec2(landmark.x, landmark.y);

Vec2 midpoint(PoseLandmark a, PoseLandmark b) =>
    Vec2((a.x + b.x) / 2, (a.y + b.y) / 2);

double distance(Vec2 a, Vec2 b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

/// 3D distance between two landmarks, including ML Kit's z (depth) axis,
/// which Google's docs state uses roughly the same scale as x. A 2D-only
/// (x, y) distance badly undercounts motion that's mostly along the
/// camera's depth axis — e.g. a jab thrown straight at a front-facing
/// camera barely shifts in (x, y) but extends substantially in z.
double distance3D(PoseLandmark a, PoseLandmark b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  final dz = a.z - b.z;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

/// Returns true only if every given landmark is confidently detected.
bool allConfident(List<PoseLandmark?> landmarks,
    {double minLikelihood = kMinLikelihood}) {
  for (final l in landmarks) {
    if (l == null || l.likelihood < minLikelihood) return false;
  }
  return true;
}

/// Interior angle at [vertex] formed by rays to [a] and [b], in degrees.
double angleAtVertex(Vec2 vertex, Vec2 a, Vec2 b) {
  final v1 = a - vertex;
  final v2 = b - vertex;
  final dot = v1.x * v2.x + v1.y * v2.y;
  final mag1 = math.sqrt(v1.x * v1.x + v1.y * v1.y);
  final mag2 = math.sqrt(v2.x * v2.x + v2.y * v2.y);
  if (mag1 == 0 || mag2 == 0) return 0;
  final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
  return math.acos(cosAngle) * 180 / math.pi;
}

/// Angle of the vector from [from] to [to], measured from vertical (0 =
/// perfectly vertical, 90 = horizontal), in degrees. Always non-negative.
double angleFromVertical(Vec2 from, Vec2 to) {
  final v = to - from;
  if (v.x == 0 && v.y == 0) return 0;
  final angleFromVerticalRad = math.atan2(v.x.abs(), v.y.abs());
  return angleFromVerticalRad * 180 / math.pi;
}

/// Scale-invariant reference length: distance from shoulder midpoint to hip
/// midpoint. All ratio-based thresholds are normalized against this so
/// checks work regardless of how far the phone is from the boxer.
double torsoLength(PoseLandmark leftShoulder, PoseLandmark rightShoulder,
    PoseLandmark leftHip, PoseLandmark rightHip) {
  final shoulderMid = midpoint(leftShoulder, rightShoulder);
  final hipMid = midpoint(leftHip, rightHip);
  return distance(shoulderMid, hipMid);
}

/// Facial landmarks are small targets and, importantly, a correctly raised
/// guard often covers the nose/mouth from the front camera — so they're
/// trusted at a lower confidence than body joints rather than dropping the
/// chin check whenever the guard is doing its job.
const double kHeadLandmarkMinLikelihood = 0.3;

/// Best-effort head-position point, used only to draw a visible "the app is
/// tracking your head" dot: prefers the nose, falls back to an ear average.
/// Returns null if no head landmark is confident enough to use.
Vec2? headReferencePoint(Pose pose) {
  final lm = pose.landmarks;
  final nose = lm[PoseLandmarkType.nose];
  if (nose != null && nose.likelihood >= kHeadLandmarkMinLikelihood) {
    return vecOf(nose);
  }

  final ears = [lm[PoseLandmarkType.leftEar], lm[PoseLandmarkType.rightEar]]
      .whereType<PoseLandmark>()
      .where((e) => e.likelihood >= kHeadLandmarkMinLikelihood)
      .toList();
  if (ears.isEmpty) return null;
  final avgX = ears.map((e) => e.x).reduce((a, b) => a + b) / ears.length;
  final avgY = ears.map((e) => e.y).reduce((a, b) => a + b) / ears.length;
  return Vec2(avgX, avgY);
}

/// Head-pitch "chin up" (not tucked) heuristic: compares nose height to
/// ear height rather than nose height to the shoulder line. Tilting the
/// head back to lift the chin swings the nose up relative to the ear(s);
/// tucking the chin drops the nose below ear level. This tracks the actual
/// head-tilt rotation directly, instead of the nose-to-shoulder gap (which
/// is dominated by roughly-constant neck length and barely moves for a
/// pure tilt, since the whole head/neck stays about as tall regardless of
/// pitch). It's a clearer, more reliable signal from a side view — the
/// rotation is seen edge-on there — and a real but weaker one from the
/// front, where only its vertical component is visible.
/// Returns null when the nose or no ear is confident enough to evaluate.
const double kChinUpNoseEarThreshold = 0.12;

bool? isChinUp(Pose pose, double torso) {
  final lm = pose.landmarks;
  final nose = lm[PoseLandmarkType.nose];
  if (nose == null || nose.likelihood < kHeadLandmarkMinLikelihood) {
    return null;
  }
  final ears = [lm[PoseLandmarkType.leftEar], lm[PoseLandmarkType.rightEar]]
      .whereType<PoseLandmark>()
      .where((e) => e.likelihood >= kHeadLandmarkMinLikelihood)
      .toList();
  if (ears.isEmpty) return null;

  final earY = ears.map((e) => e.y).reduce((a, b) => a + b) / ears.length;
  final gap = (earY - nose.y) / torso; // positive = nose above ear = chin up
  return gap > kChinUpNoseEarThreshold;
}

/// Simple exponential moving average smoother for a single scalar signal,
/// used to reduce frame-to-frame landmark jitter before rule evaluation.
class EmaSmoother {
  final double alpha;
  double? _value;

  EmaSmoother({this.alpha = 0.4});

  double next(double sample) {
    _value = _value == null ? sample : (alpha * sample + (1 - alpha) * _value!);
    return _value!;
  }

  void reset() => _value = null;
}
