import 'package:camera/camera.dart';

enum LocalVideoSource { recorded, imported }

/// A finalized local reference, with metadata obtained during finalization.
class LocalVideoSelection {
  const LocalVideoSelection(
    this.file, {
    required this.finalizedByteLength,
    this.source = LocalVideoSource.recorded,
    this.displayName,
  });
  final XFile file;
  final int finalizedByteLength;
  final LocalVideoSource source;
  final String? displayName;
  String get filename =>
      (displayName ?? file.name).replaceAll('\\', '/').split('/').last;
}

/// Independent from the Photo CaptureSession and transient recording operations.
class VideoCaptureSession {
  LocalVideoSelection? _currentVideo;
  int _revision = 0;
  int get revision => _revision;
  LocalVideoSelection? get currentVideo => _currentVideo;
  bool get hasVideo => _currentVideo != null;
  bool get canReview => hasVideo;

  /// Called only with a valid finalized recording/import; never clears on failure.
  void replace(LocalVideoSelection video) {
    _currentVideo = video;
    ++_revision;
  }

  void select(LocalVideoSelection video) => replace(video);
}
