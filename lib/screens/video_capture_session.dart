import 'package:camera/camera.dart';

enum LocalVideoSource { recorded }

/// A finalized local reference, with metadata obtained during finalization.
class LocalVideoSelection {
  const LocalVideoSelection(this.file, {required this.finalizedByteLength});
  final XFile file;
  final int finalizedByteLength;
  LocalVideoSource get source => LocalVideoSource.recorded;
}

/// Independent from the Photo CaptureSession and transient recording operations.
class VideoCaptureSession {
  LocalVideoSelection? _currentVideo;
  LocalVideoSelection? get currentVideo => _currentVideo;
  bool get hasVideo => _currentVideo != null;
  bool get canReview => hasVideo;

  /// Called only with a valid finalized recording; never clears on start/failure.
  void select(LocalVideoSelection video) => _currentVideo = video;
}
