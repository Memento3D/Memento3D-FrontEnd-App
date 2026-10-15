import 'dart:async';

import '../models/photo_upload_manifest.dart';
import '../models/photo_upload_failure.dart';
import '../models/upload_progress_snapshot.dart';
import '../repositories/photo_upload_repository.dart';
import '../repositories/upload_progress_source.dart';

class SequentialPhotoUploadSource implements UploadProgressSource {
  SequentialPhotoUploadSource({
    required this.manifest,
    required this.repository,
  }) {
    _current = _snapshot(UploadProgressStatus.preparing);
  }
  final PhotoUploadManifest manifest;
  final PhotoUploadRepository repository;
  final _events = StreamController<UploadProgressSnapshot>.broadcast(
    sync: true,
  );
  final List<ConfirmedPhotoUpload> _confirmed = [];
  List<ConfirmedPhotoUpload> get confirmed => List.unmodifiable(_confirmed);
  PhotoUploadFailure? failure;
  PhotoUploadItem? get currentItem => _confirmed.length < manifest.items.length
      ? manifest.items[_confirmed.length]
      : null;
  PhotoUploadResult? result;
  late UploadProgressSnapshot _current;
  bool _started = false, _busy = false, _closed = false;
  @override
  UploadProgressSnapshot get current => _current;
  @override
  Stream<UploadProgressSnapshot> get snapshots => _events.stream;

  UploadProgressSnapshot _snapshot(UploadProgressStatus status) =>
      UploadProgressSnapshot(
        status: status,
        confirmedUnits: _confirmed.length,
        totalUnits: manifest.items.length,
        uploadIdentity: manifest.id,
        failure: failure == null
            ? null
            : switch (failure!.kind) {
                PhotoUploadFailureKind.notSubmitted =>
                  UploadFailure.notSubmitted,
                PhotoUploadFailureKind.rejected => UploadFailure.rejected,
                PhotoUploadFailureKind.ambiguous => UploadFailure.ambiguous,
              },
        failureMessage: failure?.kind == PhotoUploadFailureKind.rejected
            ? failure?.message
            : null,
        photoStatuses: [
          for (var i = 0; i < manifest.items.length; i++)
            i < _confirmed.length
                ? UploadPhotoStatus.completed
                : i == _confirmed.length
                ? UploadPhotoStatus.current
                : UploadPhotoStatus.pending,
        ],
      );
  void _emit(UploadProgressStatus status) {
    _current = _snapshot(status);
    if (!_closed) _events.add(_current);
  }

  Future<void> start() async {
    if (_started || _closed) return;
    _started = true;
    await _run();
  }

  Future<void> _run() async {
    if (_busy || _closed) return;
    _busy = true;
    failure = null;
    _emit(UploadProgressStatus.uploading);
    try {
      while (!_closed && currentItem != null) {
        final item = currentItem!;
        try {
          final image = await repository.uploadPhoto(
            scanId: manifest.scanId,
            photo: item.file,
          );
          if (image.scanId.toLowerCase() != manifest.scanId.toLowerCase() ||
              image.uploadStatus != 'uploaded') {
            throw const PhotoUploadFailure(
              PhotoUploadFailureKind.ambiguous,
              'Unconfirmed response',
            );
          }
          // Retain an in-flight confirmation even when its screen has closed.
          _confirmed.add(ConfirmedPhotoUpload(item, image));
        } on PhotoUploadFailure catch (error) {
          failure = error;
          _emit(UploadProgressStatus.recoverableFailure);
          return;
        } catch (_) {
          failure = const PhotoUploadFailure(
            PhotoUploadFailureKind.ambiguous,
            'Upload outcome unknown',
          );
          _emit(UploadProgressStatus.recoverableFailure);
          return;
        }
        if (_closed) return;
        if (currentItem == null) {
          result = PhotoUploadResult(manifest, _confirmed);
          _emit(UploadProgressStatus.completed);
        } else {
          _emit(UploadProgressStatus.uploading);
        }
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Future<UploadProgressSnapshot> retry() async {
    if (!_closed &&
        !_busy &&
        failure?.kind == PhotoUploadFailureKind.notSubmitted) {
      await _run();
    }
    return current;
  }

  /// Stops future requests, not a POST already transmitted to the server.
  Future<void> dispose() async {
    _closed = true;
    await _events.close();
  }
}
