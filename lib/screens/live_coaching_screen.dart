import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/angle_mode.dart';
import '../models/round_config.dart';
import '../models/workout_mode.dart';
import '../services/audio/bell_player.dart';
import '../services/audio/tts_service.dart';
import '../services/pose_analysis/front_rule_set.dart';
import '../services/pose_analysis/left_side_rule_set.dart';
import '../services/pose_analysis/pose_coaching_service.dart';
import '../services/pose_analysis/right_side_rule_set.dart';
import '../services/pose_analysis/rule_set.dart';
import '../services/session/round_timer_controller.dart';
import '../services/session/session_repository.dart';
import '../services/session/session_state.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/pose_overlay_painter.dart';
import '../widgets/punch_counter_display.dart';
import '../widgets/round_indicator.dart';
import 'summary_screen.dart';

/// The camera + live-coaching screen for both workout modes.
class LiveCoachingScreen extends StatefulWidget {
  final WorkoutMode mode;
  final AngleMode angle;
  final RoundConfig? roundConfig;
  final CameraLensDirection cameraLens;

  const LiveCoachingScreen({
    super.key,
    required this.mode,
    required this.angle,
    this.roundConfig,
    this.cameraLens = CameraLensDirection.front,
  }) : assert(mode != WorkoutMode.roundTimer || roundConfig != null);

  @override
  State<LiveCoachingScreen> createState() => _LiveCoachingScreenState();
}

class _LiveCoachingScreenState extends State<LiveCoachingScreen> {
  late final SessionState _sessionState;
  late final TtsService _ttsService;
  late final BellPlayer _bellPlayer;
  late final PoseCoachingService _poseCoachingService;
  RoundTimerController? _roundTimerController;

  Timer? _elapsedTimer;
  final Stopwatch _stopwatch = Stopwatch();
  bool _cameraReady = false;
  bool _ended = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _sessionState = SessionState(mode: widget.mode, angle: widget.angle);
    _ttsService = TtsService();
    _bellPlayer = BellPlayer();
    _poseCoachingService = PoseCoachingService(
      ruleSet: _ruleSetFor(widget.angle),
      sessionState: _sessionState,
      ttsService: _ttsService,
    );

    if (widget.mode == WorkoutMode.roundTimer) {
      _roundTimerController = RoundTimerController(
        config: widget.roundConfig!,
        bellPlayer: _bellPlayer,
      )..addListener(_onRoundPhaseChanged);
    }

    _init();
  }

  FormRuleSet _ruleSetFor(AngleMode angle) {
    switch (angle) {
      case AngleMode.front:
        return FrontRuleSet();
      case AngleMode.leftSide:
        return LeftSideRuleSet();
      case AngleMode.rightSide:
        return RightSideRuleSet();
    }
  }

  Future<void> _init() async {
    await _ttsService.init();
    try {
      await _poseCoachingService.initializeCamera(
        preferredLens: widget.cameraLens,
      );
    } catch (e) {
      if (mounted) setState(() => _initError = 'Camera error: $e');
      return;
    }
    if (!mounted) return;

    setState(() => _cameraReady = true);
    _sessionState.start();
    _stopwatch.start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionState.updateElapsed(_stopwatch.elapsed);
    });
    _poseCoachingService.startAnalyzing();
    _roundTimerController?.start();
  }

  void _onRoundPhaseChanged() {
    final controller = _roundTimerController;
    if (controller == null) return;
    _sessionState.updateCurrentRound(controller.currentRound);

    if (controller.phase == RoundPhase.active) {
      _poseCoachingService.resumeAnalyzing();
    } else if (controller.phase == RoundPhase.rest) {
      _poseCoachingService.pauseAnalyzing();
    } else if (controller.phase == RoundPhase.finished) {
      _endSession();
    }
  }

  Future<void> _endSession() async {
    if (_ended) return;
    _ended = true;
    // Stop rendering the camera preview *before* disposing the controller.
    // CameraController.dispose() notifies its own listenable during teardown,
    // and if CameraPreview is still in the tree when that happens, it rebuilds
    // and calls buildPreview() on a controller that's already disposed/mid-
    // dispose, throwing a CameraException. Flipping _cameraReady first removes
    // CameraPreview from the tree so no such rebuild can occur.
    if (mounted) setState(() => _cameraReady = false);
    _elapsedTimer?.cancel();
    _stopwatch.stop();
    _roundTimerController?.stop();

    await _poseCoachingService.dispose();
    await _ttsService.dispose();
    await _bellPlayer.dispose();

    final result = _sessionState.buildResult(
      roundsCompleted: _roundTimerController?.currentRound,
    );
    await SessionRepository().save(result);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SummaryScreen(result: result)),
    );
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _roundTimerController?.removeListener(_onRoundPhaseChanged);
    _roundTimerController?.dispose();
    if (!_ended) {
      _poseCoachingService.dispose();
      _ttsService.dispose();
      _bellPlayer.dispose();
    }
    super.dispose();
  }

  /// Mirrors the preview + pose-dot overlay together for the front camera so
  /// it feels like a natural mirror; the underlying analysis pipeline still
  /// works on unmirrored frame bytes, this only affects what's drawn.
  Widget _mirrorIfFront(Widget child) {
    if (widget.cameraLens != CameraLensDirection.front) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(3.14159),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_initError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (!_cameraReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = _poseCoachingService.cameraController!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _mirrorIfFront(
            Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                ValueListenableBuilder<Pose?>(
                  valueListenable: _poseCoachingService.latestPose,
                  builder: (context, pose, _) {
                    return CustomPaint(
                      painter: PoseOverlayPainter(
                        pose: pose,
                        imageSize: _poseCoachingService.latestImageSize,
                        rotation: _poseCoachingService.latestImageRotation,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _endSession,
                      ),
                      AnimatedBuilder(
                        animation:
                            Listenable.merge([_sessionState, ?_roundTimerController]),
                        builder: (context, _) {
                          final roundController = _roundTimerController;
                          if (widget.mode == WorkoutMode.roundTimer &&
                              roundController != null) {
                            return RoundIndicator(
                              controller: roundController,
                              totalRounds: widget.roundConfig!.numRounds,
                            );
                          }
                          return PunchCounterDisplay(
                            punchCount: _sessionState.punchCount,
                          );
                        },
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _sessionState,
                    builder: (context, _) =>
                        FeedbackBanner(activeIssues: _sessionState.activeIssues),
                  ),
                  const SizedBox(height: 24),
                  if (widget.mode == WorkoutMode.freeShadow)
                    ElevatedButton(
                      onPressed: _endSession,
                      child: const Text('Stop'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
