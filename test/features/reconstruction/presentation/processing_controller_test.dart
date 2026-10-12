import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/controllers/processing_controller.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/processing_state.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/services/processing_progress_source.dart';

class TestSource implements ProcessingProgressSource {
  final stream = StreamController<ProcessingUpdate>.broadcast(sync: true);
  @override
  ProcessingUpdate current = ProcessingUpdate(
    0,
    ProcessingSnapshot(status: ProcessingStatus.processing),
  );
  final retryGate = Completer<void>();
  int retries = 0;
  bool disposed = false;
  @override
  Stream<ProcessingUpdate> get updates => stream.stream;
  void emit(ProcessingSnapshot state, {int attempt = 0}) {
    current = ProcessingUpdate(attempt, state);
    stream.add(current);
  }

  @override
  Future<void> retry(int attempt) async {
    retries++;
    await retryGate.future;
    emit(
      ProcessingSnapshot(status: ProcessingStatus.processing),
      attempt: attempt,
    );
  }

  @override
  void dispose() {
    disposed = true;
    unawaited(stream.close());
  }
}

void main() {
  test('retry errors are safe and permit another supported attempt', () async {
    final source = TestSource();
    final controller = ProcessingController.fromProgressSource(source);
    addTearDown(controller.dispose);
    source.emit(
      ProcessingSnapshot(status: ProcessingStatus.failed, canRetry: true),
    );
    final pending = controller.retry();
    source.retryGate.completeError(StateError('private exception'));
    await pending;
    expect(controller.snapshot.status, ProcessingStatus.failed);
    expect(controller.snapshot.failure, ProcessingFailure.sourceUnavailable);
    expect(controller.snapshot.errorMessage, isNull);
    expect(controller.isRetrying, isFalse);
    expect(controller.snapshot.canRetry, isTrue);
  });
  test(
    'value-identical updates are ignored and terminal states are protected',
    () {
      final source = TestSource();
      final controller = ProcessingController.fromProgressSource(source);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      source.emit(ProcessingSnapshot(status: ProcessingStatus.processing));
      expect(notifications, 0);
      source.emit(
        ProcessingSnapshot(
          status: ProcessingStatus.processing,
          progressPercent: 100,
          provenance: ProgressProvenance.measured,
        ),
      );
      expect(controller.snapshot.isTerminal, isFalse);
      source.emit(ProcessingSnapshot(status: ProcessingStatus.completed));
      source.emit(ProcessingSnapshot(status: ProcessingStatus.processing));
      expect(controller.snapshot.status, ProcessingStatus.completed);
      expect(notifications, 2);
    },
  );

  test(
    'retry is gated, duplicate guarded and stale attempt updates ignored',
    () async {
      final source = TestSource();
      final controller = ProcessingController.fromProgressSource(source);
      addTearDown(controller.dispose);
      await controller.retry();
      expect(source.retries, 0);
      source.emit(
        ProcessingSnapshot(
          status: ProcessingStatus.failed,
          canRetry: true,
          errorMessage: 'Safe error',
        ),
      );
      final pending = controller.retry();
      await controller.retry();
      expect(source.retries, 1);
      expect(controller.isRetrying, isTrue);
      source.emit(ProcessingSnapshot(status: ProcessingStatus.completed));
      expect(controller.snapshot.status, ProcessingStatus.failed);
      source.retryGate.complete();
      await pending;
      expect(controller.snapshot.status, ProcessingStatus.processing);
      expect(controller.snapshot.errorMessage, isNull);
      expect(controller.attempt, 1);
      source.emit(
        ProcessingSnapshot(status: ProcessingStatus.completed),
        attempt: 0,
      );
      expect(controller.snapshot.status, ProcessingStatus.processing);
      source.emit(
        ProcessingSnapshot(status: ProcessingStatus.failed),
        attempt: 1,
      );
      await controller.retry();
      expect(source.retries, 1);
    },
  );

  test(
    'dispose cancels subscription and owns source cleanup during retry',
    () async {
      final source = TestSource();
      final controller = ProcessingController.fromProgressSource(source);
      source.emit(
        ProcessingSnapshot(status: ProcessingStatus.failed, canRetry: true),
      );
      final pending = controller.retry();
      controller.dispose();
      expect(source.stream.hasListener, isFalse);
      expect(source.disposed, isTrue);
      source.retryGate.complete();
      await pending;
    },
  );

  test('source errors become safe failures preserving last stage', () {
    final source = TestSource();
    final controller = ProcessingController.fromProgressSource(source);
    addTearDown(controller.dispose);
    source.emit(
      ProcessingSnapshot(
        status: ProcessingStatus.processing,
        stageStatuses: {
          ProcessingStage.texturing: ProcessingStageStatus.active,
        },
      ),
    );
    source.stream.addError(StateError('private transport details'));
    expect(controller.snapshot.failure, ProcessingFailure.sourceUnavailable);
    expect(controller.snapshot.errorMessage, isNull);
    expect(
      controller.snapshot.statusFor(ProcessingStage.texturing),
      ProcessingStageStatus.active,
    );
  });
}
