import 'dart:math' as math;

enum CaptureWizardState { ready, tilted, movingTooFast, capturedSuccessfully }

class CaptureWizardThresholds {
  const CaptureWizardThresholds();

  static const gravitySmoothing = 0.2;
  static const motionSmoothing = 0.25;
  static const tiltEnterDegrees = 18.0;
  static const tiltExitDegrees = 12.0;
  static const accelerationEnter = 1.8; // m/s²
  static const accelerationExit = 1.0; // m/s²
  static const rotationEnter = 0.9; // rad/s
  static const rotationExit = 0.5; // rad/s
  static const sustainedSamples = 3;
  static const captureFeedback = Duration(milliseconds: 1400);
}

/// Calculates device guidance from sensor samples. No plugin or UI dependency.
class CaptureWizardModel {
  double? _gravityX;
  double? _gravityY;
  double? _gravityZ;
  double? _acceleration;
  double? _rotation;
  int _motionSamples = 0;
  bool _tilted = false;
  bool _moving = false;
  DateTime? _capturedUntil;

  CaptureWizardState stateAt(DateTime now) {
    // Motion wins over tilt; both win over short capture feedback.
    if (_moving) return CaptureWizardState.movingTooFast;
    if (_tilted) return CaptureWizardState.tilted;
    if (_capturedUntil?.isAfter(now) ?? false) {
      return CaptureWizardState.capturedSuccessfully;
    }
    return CaptureWizardState.ready;
  }

  void addGravity(double x, double y, double z) {
    final alpha = CaptureWizardThresholds.gravitySmoothing;
    _gravityX = _smooth(_gravityX, x, alpha);
    _gravityY = _smooth(_gravityY, y, alpha);
    _gravityZ = _smooth(_gravityZ, z, alpha);
    // Portrait upright has gravity primarily along the phone's Y axis.
    final lateral = math.sqrt(
      _gravityX! * _gravityX! + _gravityZ! * _gravityZ!,
    );
    final degrees = math.atan2(lateral, _gravityY!) * 180 / math.pi;
    if (_tilted) {
      if (degrees < CaptureWizardThresholds.tiltExitDegrees) _tilted = false;
    } else if (degrees > CaptureWizardThresholds.tiltEnterDegrees) {
      _tilted = true;
    }
  }

  void addUserAcceleration(double x, double y, double z) {
    _acceleration = _smooth(
      _acceleration,
      math.sqrt(x * x + y * y + z * z),
      CaptureWizardThresholds.motionSmoothing,
    );
    _updateMotion();
  }

  void addRotation(double x, double y, double z) {
    _rotation = _smooth(
      _rotation,
      math.sqrt(x * x + y * y + z * z),
      CaptureWizardThresholds.motionSmoothing,
    );
    _updateMotion();
  }

  void markCaptured(DateTime now) {
    _capturedUntil = now.add(CaptureWizardThresholds.captureFeedback);
  }

  void clearGravity() {
    _gravityX = _gravityY = _gravityZ = null;
    _tilted = false;
  }

  void clearAcceleration() {
    _acceleration = null;
    _resetMotion();
  }

  void clearRotation() {
    _rotation = null;
    _resetMotion();
  }

  void resetSensors() {
    clearGravity();
    clearAcceleration();
    clearRotation();
  }

  void _updateMotion() {
    final above =
        (_acceleration ?? 0) > CaptureWizardThresholds.accelerationEnter ||
        (_rotation ?? 0) > CaptureWizardThresholds.rotationEnter;
    final below =
        (_acceleration ?? 0) < CaptureWizardThresholds.accelerationExit &&
        (_rotation ?? 0) < CaptureWizardThresholds.rotationExit;
    if (!_moving && above) {
      _motionSamples++;
      if (_motionSamples >= CaptureWizardThresholds.sustainedSamples) {
        _moving = true;
        _motionSamples = 0;
      }
    } else if (_moving && below) {
      _motionSamples++;
      if (_motionSamples >= CaptureWizardThresholds.sustainedSamples) {
        _moving = false;
        _motionSamples = 0;
      }
    } else {
      _motionSamples = 0;
    }
  }

  void _resetMotion() {
    _moving = false;
    _motionSamples = 0;
  }

  static double _smooth(double? old, double value, double alpha) =>
      old == null ? value : old + alpha * (value - old);
}
