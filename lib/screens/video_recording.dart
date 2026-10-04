import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'video_capture_session.dart';
export 'video_capture_session.dart';

enum VideoRecordingState { idle, starting, recording, stopping, error }

enum VideoRecordingError { unavailable, start, finalize }

abstract interface class VideoRecorder {
  bool get available;
  Future<void> start();
  Future<XFile> stop();
}

class CameraVideoRecorder implements VideoRecorder {
  CameraVideoRecorder(this.controller);
  final CameraController controller;
  @override
  bool get available => controller.value.isInitialized;
  @override
  Future<void> start() =>
      controller.startVideoRecording(enablePersistentRecording: false);
  @override
  Future<XFile> stop() => controller.stopVideoRecording();
}

/// Read-only view used by the development device harness.
abstract interface class VideoRecordingDiagnostics implements Listenable {
  VideoRecordingState get state;
  VideoCaptureSession get videoSession;
}

/// Serializes plugin operations; camera ownership remains with CameraScreen.
class VideoRecordingCoordinator extends ChangeNotifier
    implements VideoRecordingDiagnostics {
  @override
  VideoRecordingState state = VideoRecordingState.idle;
  VideoRecordingError? error;
  @override
  final VideoCaptureSession videoSession = VideoCaptureSession();
  Duration elapsed = Duration.zero;
  Timer? _timer;
  Future<void>? _operation;
  VideoRecorder? _active;
  bool _closed = false;
  bool _quiescing = false;
  bool get busy =>
      state == VideoRecordingState.starting ||
      state == VideoRecordingState.recording ||
      state == VideoRecordingState.stopping;
  void _emit() {
    if (!_closed) notifyListeners();
  }

  Future<void> start(VideoRecorder? recorder) {
    if (_closed || _quiescing || busy) return Future.value();
    if (recorder == null || !recorder.available) {
      error = VideoRecordingError.unavailable;
      state = VideoRecordingState.error;
      _emit();
      return Future.value();
    }
    state = VideoRecordingState.starting;
    error = null;
    elapsed = Duration.zero;
    _active = recorder;
    // Install the future before notifying listeners (including exit handlers).
    final operation = _start(recorder);
    _operation = operation;
    _emit();
    return operation;
  }

  Future<void> _start(VideoRecorder recorder) async {
    try {
      await recorder.start();
      state = VideoRecordingState.recording;
      if (!_closed && !_quiescing) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          elapsed += const Duration(seconds: 1);
          _emit();
        });
      }
    } catch (_) {
      _active = null;
      state = VideoRecordingState.error;
      error = VideoRecordingError.start;
    }
    _emit();
  }

  Future<void> stop() {
    if (state == VideoRecordingState.stopping) {
      return _operation ?? Future.value();
    }
    if (state != VideoRecordingState.recording) return Future.value();
    state = VideoRecordingState.stopping;
    _stopTimer();
    final operation = _stop(_active!);
    _operation = operation;
    _emit();
    return operation;
  }

  Future<void> _stop(VideoRecorder recorder) async {
    try {
      final file = await recorder.stop();
      // Stat only: never read the video into memory or impose Phase C limits.
      final bytes = await file.length();
      if (file.path.trim().isEmpty || bytes <= 0) {
        throw StateError('Empty recording');
      }
      if (!_closed) {
        videoSession.select(
          LocalVideoSelection(file, finalizedByteLength: bytes),
        );
      }
      state = VideoRecordingState.idle;
    } catch (_) {
      state = VideoRecordingState.error;
      error = VideoRecordingError.finalize;
    } finally {
      _active = null;
      _stopTimer();
      _emit();
    }
  }

  /// Used by both exit and lifecycle before releasing the shared camera.
  Future<void> quiesce() async {
    _quiescing = true;
    try {
      await _operation;
      if (state == VideoRecordingState.recording) await stop();
      await _operation;
    } finally {
      _stopTimer();
      _quiescing = false;
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _closed = true;
    _stopTimer();
    // Emergency external route disposal still stops before camera disposal.
    unawaited(quiesce());
    super.dispose();
  }
}
