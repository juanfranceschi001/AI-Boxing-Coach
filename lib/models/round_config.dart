/// User-configured settings for Round Timer mode.
class RoundConfig {
  final Duration roundLength;
  final Duration restLength;
  final int numRounds;

  const RoundConfig({
    this.roundLength = const Duration(minutes: 3),
    this.restLength = const Duration(seconds: 60),
    this.numRounds = 3,
  });

  RoundConfig copyWith({
    Duration? roundLength,
    Duration? restLength,
    int? numRounds,
  }) {
    return RoundConfig(
      roundLength: roundLength ?? this.roundLength,
      restLength: restLength ?? this.restLength,
      numRounds: numRounds ?? this.numRounds,
    );
  }
}
