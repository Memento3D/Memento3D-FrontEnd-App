import 'package:flutter/foundation.dart';

import 'capture_session.dart';
import 'processing_state.dart';

/// Callback signature used to submit an image-to-3D generation request.
///
/// The production capture host supplies its API-backed reconstruction call.
typedef ModelGenerationSubmitter = Future<ProcessingSnapshot> Function(
  CaptureSession session,
);

/// A host must supply its API-backed submitter; never simulate submission.
Future<ProcessingSnapshot> submitCaptureSession(CaptureSession session) async {
  throw StateError('A backend reconstruction submitter is required.');
}

/// Presentation state for the "Create 3D Model from Photos — Confirmation"
/// screen.
///
/// Validation, warning and submission state live here so the amber warning is
/// driven by screen state rather than hardcoded UI logic.
class ModelConfirmationState extends ChangeNotifier {
  ModelConfirmationState({required this.session});

  final CaptureSession session;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Blocking validation: at least one photo must be ready to submit.
  bool get canSubmit => session.photoCount > 0 && !_isSubmitting;

  /// Amber warning is shown only when there is nothing to reconstruct.
  bool get showWarning => session.photoCount == 0;

  void beginSubmission() {
    if (!canSubmit) return;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void failSubmission(String message) {
    _isSubmitting = false;
    _errorMessage = message;
    notifyListeners();
  }

  void resetSubmission() {
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }
}
