/// The two supported workout modes.
enum WorkoutMode {
  roundTimer,
  freeShadow;

  String get label {
    switch (this) {
      case WorkoutMode.roundTimer:
        return 'Round Timer';
      case WorkoutMode.freeShadow:
        return 'Free / Shadow Box';
    }
  }

  String get description {
    switch (this) {
      case WorkoutMode.roundTimer:
        return 'Timed rounds with a bell and rest breaks';
      case WorkoutMode.freeShadow:
        return 'Throw punches until you stop yourself';
    }
  }
}
