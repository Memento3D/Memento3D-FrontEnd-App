import 'dart:async';

import '../domain/models/upload_progress_snapshot.dart';
import '../domain/repositories/upload_progress_source.dart';

/// Development-only manual source. No timers, networking, storage, chunk
/// protocol, or Wi-Fi detection. Never constructed by production main/Review.
class ManualUploadProgressSource implements UploadProgressSource {
  ManualUploadProgressSource()
    : _current = _sample(UploadProgressStatus.uploading);

  final _snapshots = StreamController<UploadProgressSnapshot>.broadcast(
    sync: true,
  );
  UploadProgressSnapshot _current;
  int retryCount = 0;

  @override
  UploadProgressSnapshot get current => _current;
  @override
  Stream<UploadProgressSnapshot> get snapshots => _snapshots.stream;

  void show(UploadProgressStatus status) {
    _current = _sample(status);
    _snapshots.add(_current);
  }

  @override
  Future<UploadProgressSnapshot> retry() async {
    retryCount++;
    _current = _sample(UploadProgressStatus.uploading);
    return _current;
  }

  Future<void> dispose() => _snapshots.close();

  static UploadProgressSnapshot _sample(UploadProgressStatus status) {
    final complete = status == UploadProgressStatus.completed;
    return UploadProgressSnapshot(
      status: status,
      confirmedUnits: complete ? 50 : 34,
      totalUnits: 50,
      acknowledgedBytes: complete ? 142 * 1024 * 1024 : 96 * 1024 * 1024,
      totalBytes: 142 * 1024 * 1024,
      bytesPerSecond: status == UploadProgressStatus.uploading ? 2400000 : null,
      estimatedRemaining: status == UploadProgressStatus.uploading
          ? const Duration(seconds: 80)
          : null,
      uploadIdentity: 'development-preview-attempt',
      failure: status == UploadProgressStatus.recoverableFailure
          ? UploadFailure.interrupted
          : null,
      photoStatuses: complete
          ? List.filled(4, UploadPhotoStatus.completed)
          : const [
              UploadPhotoStatus.completed,
              UploadPhotoStatus.completed,
              UploadPhotoStatus.current,
              UploadPhotoStatus.pending,
            ],
    );
  }
}
