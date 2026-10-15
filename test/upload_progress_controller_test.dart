import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/uploads/development/manual_upload_progress_source.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/upload_progress_snapshot.dart';
import 'package:memento3d_frontend_app/features/uploads/presentation/controllers/upload_progress_controller.dart';

import 'support/controlled_upload_progress_source.dart';

void main() {
  group('snapshot validation', () {
    test(
      'derives progress from confirmed units, independently of bytes/photos',
      () {
        final snapshot = uploadSnapshot();
        expect(snapshot.confirmedProgress, 0.68);
        expect(snapshot.progressPercent, 68);
        expect(snapshot.photoStatuses.length, 4);
        expect(snapshot.acknowledgedBytes, 3400);
        expect(() => snapshot.photoStatuses.clear(), throwsUnsupportedError);
      },
    );

    for (final counts in [(-1, 50), (51, 50), (0, -1), (0, 0)]) {
      test('rejects active counts $counts at runtime', () {
        expect(
          () => uploadSnapshot(confirmed: counts.$1, total: counts.$2),
          throwsArgumentError,
        );
      });
    }

    test(
      'preparing can have unknown units, bytes, speed, ETA and identity',
      () {
        final snapshot = UploadProgressSnapshot(
          status: UploadProgressStatus.preparing,
          confirmedUnits: 0,
          totalUnits: 0,
        );
        expect(snapshot.confirmedProgress, 0);
        expect(snapshot.totalBytes, isNull);
        expect(snapshot.uploadIdentity, isNull);
        expect(snapshot.visibleBytesPerSecond, isNull);
        expect(snapshot.visibleRemaining, isNull);
      },
    );

    test('completion requires all units and is never inferred from counts', () {
      expect(
        () => uploadSnapshot(status: UploadProgressStatus.completed),
        throwsArgumentError,
      );
      final snapshot = uploadSnapshot(confirmed: 50);
      expect(snapshot.status, UploadProgressStatus.uploading);
      expect(snapshot.confirmedProgress, 1);
    });

    test('rejects invalid bytes, rates, duration and misplaced failure', () {
      for (final speed in [-1.0, double.nan, double.infinity]) {
        expect(
          () => UploadProgressSnapshot(
            status: UploadProgressStatus.uploading,
            confirmedUnits: 1,
            totalUnits: 2,
            bytesPerSecond: speed,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => UploadProgressSnapshot(
          status: UploadProgressStatus.uploading,
          confirmedUnits: 1,
          totalUnits: 2,
          acknowledgedBytes: 11,
          totalBytes: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => UploadProgressSnapshot(
          status: UploadProgressStatus.uploading,
          confirmedUnits: 1,
          totalUnits: 2,
          totalBytes: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => UploadProgressSnapshot(
          status: UploadProgressStatus.uploading,
          confirmedUnits: 1,
          totalUnits: 2,
          estimatedRemaining: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => UploadProgressSnapshot(
          status: UploadProgressStatus.uploading,
          confirmedUnits: 1,
          totalUnits: 2,
          failure: UploadFailure.interrupted,
        ),
        throwsArgumentError,
      );
    });
  });

  group('controller', () {
    late ControlledUploadProgressSource source;
    late UploadProgressController controller;
    setUp(() {
      source = ControlledUploadProgressSource(uploadSnapshot());
      controller = UploadProgressController(source: source);
    });
    tearDown(() async {
      controller.dispose();
      await source.dispose();
    });

    test('waiting and reconciliation preserve confirmed position and suppress metrics', () {
      for (final status in [
        UploadProgressStatus.waitingForNetwork,
        UploadProgressStatus.reconciling,
      ]) {
        source.emit(uploadSnapshot(status: status));
        expect(controller.state.status, status);
        expect(controller.state.confirmedUnits, 34);
        expect(controller.state.progressPercent, 68);
        expect(controller.state.visibleBytesPerSecond, isNull);
        expect(controller.state.visibleRemaining, isNull);
        expect(controller.canRetry, isFalse);
      }
      source.emit(uploadSnapshot(confirmed: 35));
      expect(controller.state.confirmedUnits, 35);
    });

    test(
      'retry is explicit, guarded and preserves counts while pending',
      () async {
        await controller.retry();
        expect(source.retries, isEmpty);
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
        );
        var retryEnabledAfterNotification = false;
        controller.addListener(() {
          retryEnabledAfterNotification = controller.canRetry;
          if (controller.state.status == UploadProgressStatus.reconciling) {
            controller.retry();
          }
        });
        final pending = controller.retry();
        await controller.retry();
        expect(source.retries.length, 1);
        expect(controller.state.status, UploadProgressStatus.reconciling);
        expect(controller.state.progressPercent, 68);
        source.retries.single.complete(
          uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
        );
        await pending;
        expect(controller.canRetry, isTrue);
        expect(retryEnabledAfterNotification, isTrue);
        final retry = controller.retry();
        source.retries.last.complete(uploadSnapshot());
        await retry;
        expect(controller.state.status, UploadProgressStatus.uploading);
        expect(controller.state.progressPercent, 68);
      },
    );

    test(
      'raw retry errors become safe recoverable state without reset',
      () async {
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
        );
        final retry = controller.retry();
        source.retries.single.completeError(
          StateError('private adapter details'),
        );
        await retry;
        expect(controller.state.failure, UploadFailure.sourceUnavailable);
        expect(controller.state.progressPercent, 68);
        expect(controller.canRetry, isTrue);
      },
    );

    test('regressing counts, different identity and changed totals cannot mutate current state', () {
      final snapshot = controller.state;
      source.emit(uploadSnapshot(confirmed: 33));
      source.emit(uploadSnapshot(identity: 'another-attempt'));
      source.emit(uploadSnapshot(total: 51));
      source.emit(
        UploadProgressSnapshot(
          status: UploadProgressStatus.uploading,
          confirmedUnits: 34,
          totalUnits: 50,
          uploadIdentity: 'test-attempt',
          acknowledgedBytes: 3399,
        ),
      );
      expect(controller.state, same(snapshot));
    });

    test('invalid retry snapshot returns to recoverable failure rather than resetting', () async {
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
      );
      final retry = controller.retry();
      source.retries.single.complete(uploadSnapshot(confirmed: 0));
      await retry;
      expect(controller.state.progressPercent, 68);
      expect(controller.canRetry, isTrue);
    });

    for (final outcome in [
      UploadProgressStatus.waitingForNetwork,
      UploadProgressStatus.completed,
    ]) {
      test('late retry result cannot overwrite newer $outcome', () async {
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
        );
        final retry = controller.retry();
        source.emit(
          uploadSnapshot(
            status: outcome,
            confirmed: outcome == UploadProgressStatus.completed ? 50 : 34,
          ),
        );
        final snapshot = controller.state;
        source.retries.single.complete(uploadSnapshot());
        await retry;
        expect(controller.state, same(snapshot));
      });
    }

    test('obsolete snapshots cannot invalidate an in-flight retry', () async {
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
      );
      final retry = controller.retry();
      source.emit(uploadSnapshot(identity: 'obsolete-attempt'));
      source.emit(uploadSnapshot(confirmed: 0));
      source.retries.single.complete(uploadSnapshot(confirmed: 35));
      await retry;
      expect(controller.state.status, UploadProgressStatus.uploading);
      expect(controller.state.confirmedUnits, 35);
    });

    test('late retry error cannot overwrite a newer completed state', () async {
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
      );
      final retry = controller.retry();
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
      );
      final snapshot = controller.state;
      source.retries.single.completeError(
        StateError('obsolete transport failure'),
      );
      await retry;
      expect(controller.state, same(snapshot));
      expect(controller.state.progressPercent, 100);
    });

    test('completion is explicit, terminal and claimed once', () async {
      source.emit(uploadSnapshot(confirmed: 50));
      expect(controller.takeCompletion(), isFalse);
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
      );
      expect(controller.takeCompletion(), isTrue);
      expect(controller.takeCompletion(), isFalse);
      final snapshot = controller.state;
      source.emit(
        uploadSnapshot(
          status: UploadProgressStatus.recoverableFailure,
          confirmed: 50,
        ),
      );
      source.fail(StateError('late error'));
      await controller.retry();
      expect(controller.state, same(snapshot));
      expect(source.retries, isEmpty);
    });

    test('stream failure preserves position and enables safe retry', () {
      source.fail(StateError('private transport details'));
      expect(controller.state.status, UploadProgressStatus.recoverableFailure);
      expect(controller.state.failure, UploadFailure.sourceUnavailable);
      expect(controller.state.progressPercent, 68);
      expect(controller.canRetry, isTrue);
    });

    test(
      'dispose prevents notifications, late completion and retries',
      () async {
        final disposable = UploadProgressController(source: source);
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
        );
        final retry = disposable.retry();
        var notifications = 0;
        disposable.addListener(() => notifications++);
        final snapshot = disposable.state;
        disposable.dispose();
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
        );
        source.retries.single.complete(
          uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
        );
        await retry;
        await disposable.retry();
        expect(disposable.state, same(snapshot));
        expect(disposable.takeCompletion(), isFalse);
        expect(notifications, 0);
        expect(source.retries.length, 1);
      },
    );
  });

  test(
    'manual preview retry deterministically resumes at the confirmed position',
    () async {
      final source = ManualUploadProgressSource();
      final controller = UploadProgressController(source: source);
      source.show(UploadProgressStatus.recoverableFailure);
      await controller.retry();
      expect(source.retryCount, 1);
      expect(controller.state.status, UploadProgressStatus.uploading);
      expect(controller.state.progressPercent, 68);
      expect(controller.state.supportsPersistentResume, isFalse);
      controller.dispose();
      await source.dispose();
    },
  );
}
