import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/entities/scan_image.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/photo_upload_manifest.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/photo_upload_failure.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/upload_progress_snapshot.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/repositories/photo_upload_repository.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/services/sequential_photo_upload_source.dart';

class Photo implements PhotoUploadFile {
  @override
  String get filename => 'same.jpg';
  @override
  String? get mimeType => 'image/jpeg';
  @override
  Future<int> length() async => 1;
  @override
  Stream<List<int>> openRead() => Stream.value([1]);
}

class Repository implements PhotoUploadRepository {
  final calls = <PhotoUploadFile>[];
  final pending = <Completer<ScanImage>>[];
  @override
  Future<ScanImage> uploadPhoto({
    required String scanId,
    required PhotoUploadFile photo,
  }) {
    expect(scanId, 'persisted-scan');
    calls.add(photo);
    final response = Completer<ScanImage>();
    pending.add(response);
    return response.future;
  }
}

ScanImage image(String id) => ScanImage(
  id: id,
  scanId: 'persisted-scan',
  originalFilename: 'same.jpg',
  fileSizeBytes: 1,
  mimeType: 'image/jpeg',
  format: 'jpg',
  sortOrder: 0,
  uploadStatus: 'uploaded',
  isExcluded: false,
  needsQualityCheck: true,
  createdAt: DateTime.utc(2026),
);
PhotoUploadManifest manifest(List<PhotoUploadItem> items) =>
    PhotoUploadManifest(id: 'attempt', scanId: 'persisted-scan', items: items);
List<PhotoUploadItem> items() => [
  for (var i = 0; i < 3; i++)
    PhotoUploadItem(localCaptureId: 'local-$i', file: Photo()),
];
Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'capture identities survive removal and are distinct for identical paths',
    () {
      final session = CaptureSession()
        ..addPhoto(XFile('same.jpg'))
        ..addPhoto(XFile('same.jpg'));
      final ids = session.photoEntries.map((e) => e.localCaptureId).toList();
      expect(ids.toSet().length, 2);
      session.removePhoto(session.capturedPhotos.first);
      expect(session.photoEntries.single.localCaptureId, ids.last);
    },
  );
  test('empty manifest rejected and source-list mutation cannot alter frozen order', () {
    expect(() => manifest([]), throwsArgumentError);
    final original = items();
    final frozen = manifest(original);
    original.clear();
    expect(frozen.items.map((e) => e.localCaptureId), [
      'local-0',
      'local-1',
      'local-2',
    ]);
    expect(() => frozen.items.clear(), throwsUnsupportedError);
  });
  test(
    'one request at a time, no duplicate start, progress only on confirmations',
    () async {
      final repo = Repository();
      final source = SequentialPhotoUploadSource(
        manifest: manifest(items()),
        repository: repo,
      );
      addTearDown(source.dispose);
      expect(source.current.confirmedUnits, 0);
      final run = source.start();
      await source.start();
      expect(repo.calls.length, 1);
      expect(source.result, isNull);
      final first = image('backend-0');
      repo.pending[0].complete(first);
      await tick();
      expect(repo.calls.length, 2);
      expect(source.current.confirmedUnits, 1);
      expect(source.confirmed.first.image, same(first));
      expect(source.current.acknowledgedBytes, isNull);
      repo.pending[1].complete(image('backend-1'));
      await tick();
      expect(source.current.confirmedUnits, 2);
      expect(source.result, isNull);
      repo.pending[2].complete(image('backend-2'));
      await run;
      expect(source.current.status, UploadProgressStatus.completed);
      expect(source.result!.scanId, 'persisted-scan');
      expect(source.result!.photos.map((e) => e.item.localCaptureId), [
        'local-0',
        'local-1',
        'local-2',
      ]);
      expect(source.result!.photos.map((e) => e.image.id), [
        'backend-0',
        'backend-1',
        'backend-2',
      ]);
    },
  );
  for (final kind in PhotoUploadFailureKind.values) {
    test(
      '$kind stops, retains prior confirmation, retries only notSubmitted',
      () async {
        final repo = Repository();
        final source = SequentialPhotoUploadSource(
          manifest: manifest(items()),
          repository: repo,
        );
        addTearDown(source.dispose);
        final run = source.start();
        repo.pending[0].complete(image('backend'));
        await tick();
        repo.pending[1].completeError(PhotoUploadFailure(kind, 'test'));
        await run;
        expect(repo.calls.length, 2);
        expect(source.confirmed.single.image.id, 'backend');
        expect(source.currentItem!.localCaptureId, 'local-1');
        expect(source.result, isNull);
        expect(source.current.confirmedUnits, 1);
        expect(
          source.current.canRetry,
          kind == PhotoUploadFailureKind.notSubmitted,
        );
        final retry = source.retry();
        if (kind == PhotoUploadFailureKind.notSubmitted) {
          expect(repo.calls.length, 3);
          expect(repo.calls[2], same(repo.calls[1]));
          repo.pending[2].complete(image('backend-1'));
          await tick();
          repo.pending[3].complete(image('backend-2'));
        }
        await retry;
        expect(
          repo.calls.length,
          kind == PhotoUploadFailureKind.notSubmitted ? 4 : 2,
        );
      },
    );
  }
  test(
    'dispose retains in-flight confirmation but never submits later items',
    () async {
      final repo = Repository();
      final source = SequentialPhotoUploadSource(
        manifest: manifest(items()),
        repository: repo,
      );
      final run = source.start();
      await source.dispose();
      repo.pending[0].complete(image('backend'));
      await run;
      expect(repo.calls.length, 1);
      expect(source.confirmed.length, 1);
    },
  );
}
