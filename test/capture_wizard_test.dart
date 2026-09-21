import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/screens/capture_wizard.dart';

void main() {
  final now = DateTime(2026);

  test('capture feedback expires and ready guidance returns', () {
    final wizard = CaptureWizardModel();
    wizard.markCaptured(now);
    expect(wizard.stateAt(now), CaptureWizardState.capturedSuccessfully);
    expect(
      wizard.stateAt(now.add(CaptureWizardThresholds.captureFeedback)),
      CaptureWizardState.ready,
    );
  });

  test('tilt uses smoothing and hysteresis', () {
    final wizard = CaptureWizardModel();
    wizard.addGravity(0, 9.8, 0);
    wizard.addGravity(4, 9, 0);
    expect(wizard.stateAt(now), CaptureWizardState.ready);
    for (var i = 0; i < 15; i++) {
      wizard.addGravity(4, 9, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.tilted);
    for (var i = 0; i < 15; i++) {
      wizard.addGravity(2.5, 9, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.tilted);
    for (var i = 0; i < 20; i++) {
      wizard.addGravity(0, 9.8, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.ready);
  });

  test('upside-down orientation is not treated as upright portrait', () {
    final wizard = CaptureWizardModel();
    wizard.addGravity(0, -9.8, 0);
    expect(wizard.stateAt(now), CaptureWizardState.tilted);
  });

  test('isolated motion sample is ignored but sustained motion wins', () {
    final wizard = CaptureWizardModel();
    wizard.markCaptured(now);
    wizard.addUserAcceleration(3, 0, 0);
    expect(wizard.stateAt(now), CaptureWizardState.capturedSuccessfully);
    for (var i = 0; i < 10; i++) {
      wizard.addUserAcceleration(3, 0, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.movingTooFast);
    for (var i = 0; i < 20; i++) {
      wizard.addUserAcceleration(0, 0, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.capturedSuccessfully);
  });

  test('motion has priority over tilt; tilt has priority over feedback', () {
    final wizard = CaptureWizardModel();
    wizard.markCaptured(now);
    for (var i = 0; i < 20; i++) {
      wizard.addGravity(4, 9, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.tilted);
    for (var i = 0; i < 10; i++) {
      wizard.addRotation(1.5, 0, 0);
    }
    expect(wizard.stateAt(now), CaptureWizardState.movingTooFast);
  });

  test('lost sensors clear guidance without inventing readings', () {
    final wizard = CaptureWizardModel();
    for (var i = 0; i < 20; i++) {
      wizard.addGravity(4, 9, 0);
      wizard.addRotation(1.5, 0, 0);
    }
    wizard.resetSensors();
    expect(wizard.stateAt(now), CaptureWizardState.ready);
  });
}
