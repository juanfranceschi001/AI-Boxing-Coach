import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../models/form_issue.dart';
import '../../models/workout_mode.dart';
import '../audio/tts_service.dart';
import '../session/session_state.dart';
import 'feedback_throttler.dart';
import 'punch_counter.dart';
import 'rule_set.dart';

/// Owns the camera feed, the on-device pose detector, and the per-frame
/// analysis pipeline. Ties together: camera frame -> InputImage -> Pose ->
/// FormRuleSet (angle-specific) -> FeedbackThrottler -> spoken cue + session
/// stat updates, plus punch counting in Free/Shadow mode.
///
/// Everything here runs fully on-device (no network calls), satisfying the
/// app's zero-cost requirement.
class PoseCoachingService {
  final FormRuleSet ruleSet;
  final SessionState sessionState;
  final TtsService ttsService;

  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  final FeedbackThrottler _throttler = FeedbackThrottler();
  final PunchCounter punchCounter = PunchCounter();

  CameraController? cameraController;
  CameraDescription? _cameraDescription;

  /// Latest detected pose and the image size it was detected in, exposed
  /// for the optional live skeleton overlay (see PoseOverlayPainter).
  final ValueNotifier<Pose?> latestPose = ValueNotifier(null);
  Size latestImageSize = Size.zero;
  InputImageRotation latestImageRotation = InputImageRotation.rotation0deg;

  bool _isBusy = false;
  bool _isAnalyzing = false;
  int _frameCounter = 0;

  // Only analyze every 2nd camera frame (~15fps at 30fps capture) to keep
  // inference from dropping preview FPS or overheating lower-end devices,
  // while still catching fast punch-extension peaks for punch counting.
  static const int _analyzeEveryNthFrame = 2;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  PoseCoachingService({
    required this.ruleSet,
    required this.sessionState,
    required this.ttsService,
  });

  Future<void> initializeCamera({
    CameraLensDirection preferredLens = CameraLensDirection.back,
  }) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('noCamerasAvailable', 'No cameras found on device.');
    }
    _cameraDescription = cameras.firstWhere(
      (c) => c.lensDirection == preferredLens,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      _cameraDescription!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();
    cameraController = controller;
  }

  void startAnalyzing() {
    _isAnalyzing = true;
    final controller = cameraController;
    if (controller == null || controller.value.isStreamingImages) return;
    controller.startImageStream(_onCameraImage);
  }

  /// Pauses coaching (e.g. during a rest period) without tearing down the
  /// camera stream, so resuming is instant.
  void pauseAnalyzing() {
    _isAnalyzing = false;
    _throttler.reset();
  }

  void resumeAnalyzing() {
    _isAnalyzing = true;
  }

  void _onCameraImage(CameraImage image) {
    if (_isBusy || !_isAnalyzing) return;
    _frameCounter++;
    if (_frameCounter % _analyzeEveryNthFrame != 0) return;

    _isBusy = true;
    _processImage(image).whenComplete(() => _isBusy = false);
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final poses = await _poseDetector.processImage(inputImage);
    latestImageSize = inputImage.metadata?.size ?? Size.zero;
    latestImageRotation =
        inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
    if (poses.isEmpty) {
      latestPose.value = null;
      sessionState.setActiveIssues(const []);
      return;
    }
    final pose = poses.first;
    latestPose.value = pose;
    final now = DateTime.now();

    final issues = ruleSet.evaluate(pose);
    final result = _throttler.process(issues, now: now);
    sessionState.setActiveIssues(result.activeIssues);
    for (final issue in result.cueIssues) {
      sessionState.registerCue(issue);
      ttsService.speak(issue.cue);
    }

    if (sessionState.mode == WorkoutMode.freeShadow) {
      final newPunches = punchCounter.update(pose, now);
      if (newPunches > 0) sessionState.addPunches(newPunches);
    }
  }

  /// Converts a raw camera frame into the InputImage type ML Kit expects.
  /// Adapted from google_mlkit_commons' documented camera-stream recipe;
  /// the rotation/format handling here is Android/iOS-specific and known to
  /// be finicky across devices (see plan risks).
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraDescription;
    final controller = cameraController;
    if (camera == null || controller == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    final controller = cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller?.dispose();
    await _poseDetector.close();
    latestPose.dispose();
  }
}
