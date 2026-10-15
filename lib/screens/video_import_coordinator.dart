import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'video_capture_session.dart';
import 'video_file_probe.dart';
import 'video_import_policy.dart';
import 'video_import_storage.dart';
import 'video_picker.dart';

class VideoImportResult {
  const VideoImportResult({this.replaced = false, this.error});
  final bool replaced;
  final VideoImportError? error;
}

class VideoImportCoordinator extends ChangeNotifier {
  VideoImportCoordinator({
    required this.session,
    required this.picker,
    required this.probe,
    required this.storage,
  });
  final VideoCaptureSession session;
  final VideoPicker picker;
  final VideoFileProbe probe;
  final VideoImportStorage storage;
  bool _busy = false, _closed = false;
  int _generation = 0;
  bool get busy => _busy;

  void invalidate() => ++_generation;

  Future<VideoImportResult> importVideo({
    required bool Function() isCurrent,
  }) async {
    if (_closed || _busy || !isCurrent()) return const VideoImportResult();
    _busy = true; // Synchronous duplicate-tap guard, before plugin awaits.
    final generation = ++_generation;
    final revision = session.revision;
    bool current() =>
        !_closed &&
        generation == _generation &&
        session.revision == revision &&
        isCurrent();
    notifyListeners();
    var failure = VideoImportError.picker;
    try {
      final candidate = await picker.pickVideo();
      if (!current() || candidate == null) return const VideoImportResult();
      if (!VideoImportPolicy.allowsName(candidate.displayName)) {
        return const VideoImportResult(error: VideoImportError.format);
      }
      failure = VideoImportError.unavailable;
      final facts = await probe.inspect(candidate.path);
      if (!current()) return const VideoImportResult();
      final error = VideoImportPolicy.validate(facts);
      if (error != null) return VideoImportResult(error: error);
      failure = VideoImportError.storage;
      final path = await storage.promote(candidate);
      if (!current()) return const VideoImportResult();
      final finalFacts = await probe.inspect(path);
      if (!current()) return const VideoImportResult();
      final finalError = VideoImportPolicy.validate(finalFacts);
      if (finalError != null || finalFacts.byteLength != facts.byteLength) {
        return const VideoImportResult(error: VideoImportError.storage);
      }
      session.replace(
        LocalVideoSelection(
          XFile(path),
          finalizedByteLength: finalFacts.byteLength!,
          displayName: candidate.displayName,
          source: LocalVideoSource.imported,
        ),
      );
      return const VideoImportResult(replaced: true);
    } catch (_) {
      return VideoImportResult(error: current() ? failure : null);
    } finally {
      _busy = false;
      if (!_closed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _closed = true;
    invalidate();
    super.dispose();
  }
}
