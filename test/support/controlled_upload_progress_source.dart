import 'dart:async';

import 'package:memento3d_frontend_app/features/uploads/domain/models/upload_progress_snapshot.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/repositories/upload_progress_source.dart';

UploadProgressSnapshot uploadSnapshot({
  UploadProgressStatus status = UploadProgressStatus.uploading,
  int confirmed = 34,
  int total = 50,
  String? identity = 'test-attempt',
  bool persistent = false,
}) => UploadProgressSnapshot(
  status: status,
  confirmedUnits: confirmed,
  totalUnits: total,
  acknowledgedBytes: confirmed * 100,
  totalBytes: total * 100,
  bytesPerSecond: 2400000,
  estimatedRemaining: const Duration(seconds: 80),
  uploadIdentity: identity,
  supportsPersistentResume: persistent,
  failure: status == UploadProgressStatus.recoverableFailure
      ? UploadFailure.interrupted
      : null,
  photoStatuses: const [
    UploadPhotoStatus.completed,
    UploadPhotoStatus.completed,
    UploadPhotoStatus.current,
    UploadPhotoStatus.pending,
  ],
);

class ControlledUploadProgressSource implements UploadProgressSource {
  ControlledUploadProgressSource(UploadProgressSnapshot initial)
    : _current = initial;
  UploadProgressSnapshot _current;
  final _events = StreamController<UploadProgressSnapshot>.broadcast(
    sync: true,
  );
  final List<Completer<UploadProgressSnapshot>> retries = [];

  @override
  UploadProgressSnapshot get current => _current;
  @override
  Stream<UploadProgressSnapshot> get snapshots => _events.stream;
  @override
  Future<UploadProgressSnapshot> retry() {
    final result = Completer<UploadProgressSnapshot>();
    retries.add(result);
    return result.future;
  }

  void emit(UploadProgressSnapshot snapshot) {
    _current = snapshot;
    _events.add(snapshot);
  }

  void fail(Object error) => _events.addError(error, StackTrace.current);
  Future<void> dispose() => _events.close();
}
