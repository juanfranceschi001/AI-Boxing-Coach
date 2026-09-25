import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_analysis/landmark_geometry.dart';

/// Draws dots over detected pose landmarks, mapping from the raw camera
/// buffer's coordinate space (as passed to ML Kit) into the preview
/// widget's canvas size.
///
/// ML Kit returns landmark coordinates relative to the *original* image
/// buffer dimensions (e.g. a landscape 640x480 sensor frame), not the
/// upright/rotated orientation the rotation metadata hints at. Since the
/// phone is normally held in portrait, that buffer is 90/270 degrees off
/// from what's displayed, so width/height must be swapped when mapping —
/// otherwise dots land in roughly the wrong quadrant/aspect entirely.
/// Mirroring for the front camera is handled separately by wrapping this
/// painter in the same Transform as CameraPreview, so no mirror logic is
/// needed here.
class PoseOverlayPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final InputImageRotation rotation;

  PoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    this.rotation = InputImageRotation.rotation0deg,
  });

  double _translateX(double x, Size canvasSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / imageSize.height;
      case InputImageRotation.rotation270deg:
        return canvasSize.width - (x * canvasSize.width / imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return x * canvasSize.width / imageSize.width;
    }
  }

  double _translateY(double y, Size canvasSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageSize.width;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final currentPose = pose;
    if (currentPose == null || imageSize.width == 0 || imageSize.height == 0) {
      return;
    }

    final dotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final landmark in currentPose.landmarks.values) {
      if (landmark.likelihood < 0.5) continue;
      final point = Offset(
        _translateX(landmark.x, size),
        _translateY(landmark.y, size),
      );
      canvas.drawCircle(point, 5, dotPaint);
    }

    // Highlight the head-reference point the chin-tuck check actually uses
    // (nose, or an ear fallback), in a distinct color, so it's visible even
    // when it falls below the 0.5 cutoff used for the regular green dots —
    // this is the app's own confirmation that it's tracking your head.
    final headPoint = headReferencePoint(currentPose);
    if (headPoint != null) {
      final headDotPaint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(_translateX(headPoint.x, size), _translateY(headPoint.y, size)),
        7,
        headDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.rotation != rotation;
  }
}
