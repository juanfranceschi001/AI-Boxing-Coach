import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/round_config.dart';
import '../audio/bell_player.dart';

enum RoundPhase { idle, active, rest, finished }

/// Drives round/rest countdown for Round Timer mode and triggers the bell
/// at each transition: bell_start when round 1 begins, bell_end whenever a
/// round finishes, and rest_end whenever a rest period finishes (which
/// itself signals the next round beginning, so no extra bell is played on
/// top of it).
class RoundTimerController extends ChangeNotifier {
  final RoundConfig config;
  final BellPlayer bellPlayer;

  RoundPhase phase = RoundPhase.idle;
  int currentRound = 0; // 1-based once started
  Duration remaining = Duration.zero;
  Timer? _timer;

  RoundTimerController({required this.config, required this.bellPlayer});

  bool get isRoundActive => phase == RoundPhase.active;
  bool get isFinished => phase == RoundPhase.finished;

  void start() {
    currentRound = 1;
    phase = RoundPhase.active;
    remaining = config.roundLength;
    bellPlayer.playRoundStart();
    notifyListeners();
    _startTicking();
  }

  void _beginRest() {
    phase = RoundPhase.rest;
    remaining = config.restLength;
    notifyListeners();
    _startTicking();
  }

  void _beginNextRound() {
    currentRound++;
    phase = RoundPhase.active;
    remaining = config.roundLength;
    notifyListeners();
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (remaining.inSeconds <= 1) {
      remaining = Duration.zero;
      _timer?.cancel();
      notifyListeners();
      _onPhaseComplete();
    } else {
      remaining -= const Duration(seconds: 1);
      notifyListeners();
    }
  }

  void _onPhaseComplete() {
    if (phase == RoundPhase.active) {
      bellPlayer.playRoundEnd();
      if (currentRound >= config.numRounds) {
        phase = RoundPhase.finished;
        notifyListeners();
      } else {
        _beginRest();
      }
    } else if (phase == RoundPhase.rest) {
      bellPlayer.playRestEnd();
      _beginNextRound();
    }
  }

  /// Stops early (user-initiated), without playing a completion bell.
  void stop() {
    _timer?.cancel();
    phase = RoundPhase.finished;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
