/// Which side of the boxer the camera is positioned at.
enum AngleMode {
  front,
  leftSide,
  rightSide;

  String get label {
    switch (this) {
      case AngleMode.front:
        return 'Front';
      case AngleMode.leftSide:
        return 'Left Side';
      case AngleMode.rightSide:
        return 'Right Side';
    }
  }

  String get description {
    switch (this) {
      case AngleMode.front:
        return 'Phone faces you head-on';
      case AngleMode.leftSide:
        return 'Phone is positioned at your left';
      case AngleMode.rightSide:
        return 'Phone is positioned at your right';
    }
  }
}
