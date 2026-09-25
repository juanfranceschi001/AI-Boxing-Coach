import 'package:audioplayers/audioplayers.dart';

/// Plays the round-timer bell/beep cues from bundled assets.
///
/// NOTE: bell_start.wav / bell_end.wav / rest_end.wav are synthesized
/// placeholder tones, not a real bell sound. Swap them for nicer audio in
/// assets/audio/ before release if desired.
class BellPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playRoundStart() => _play('audio/bell_start.wav');
  Future<void> playRoundEnd() => _play('audio/bell_end.wav');
  Future<void> playRestEnd() => _play('audio/rest_end.wav');

  Future<void> _play(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }

  Future<void> dispose() => _player.dispose();
}
