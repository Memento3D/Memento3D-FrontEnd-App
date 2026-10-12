import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/entities/reconstruction_job.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/reconstruction_repository.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/controllers/processing_controller.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/processing_state.dart';

class FakeRepository implements ReconstructionRepository {
  final updates = StreamController<ReconstructionJob>.broadcast(sync: true);
  final errors = StreamController<ReconstructionObservationError>.broadcast();
  bool disposed = false;
  @override
  ReconstructionJob? current;
  @override
  ReconstructionObservationError? lastObservationError;
  @override
  Stream<ReconstructionJob> get jobs => updates.stream;
  @override
  Stream<ReconstructionObservationError> get observationErrors => errors.stream;
  @override
  void cancel() {}
  @override
  Future<void> retryObservation() async {}
  @override
  void dispose() {
    disposed = true;
    unawaited(updates.close());
    unawaited(errors.close());
  }
}

void main() {
  test('controller consumes domain contract, maps state and owns disposal', () {
    final repository = FakeRepository();
    final controller = ProcessingController(repository);
    expect(controller.snapshot.status, ProcessingStatus.readyToUpload);
    repository.current = const ReconstructionJob(
      jobId: 'job',
      scanId: 'scan',
      inputImageId: 'image',
      status: ReconstructionStatus.running,
      stage: ReconstructionStage.uploading,
      progress: 10000,
      execution: ReconstructionExecution.mock,
      profile: 'opaque',
      retryCount: 7,
    );
    repository.updates.add(repository.current!);
    expect(controller.snapshot.status, ProcessingStatus.processing);
    expect(controller.snapshot.jobStage, ProcessingJobStage.uploading);
    expect(controller.snapshot.backendProgress, 10000);
    expect(controller.snapshot.progressPercent, isNull);
    expect(controller.snapshot.uploadedBytes, isNull);
    expect(controller.snapshot.provenance, ProgressProvenance.simulated);
    expect(controller.snapshot.canRetry, isFalse);
    controller.dispose();
    expect(repository.disposed, isTrue);
    expect(repository.updates.hasListener, isFalse);
  });
}
