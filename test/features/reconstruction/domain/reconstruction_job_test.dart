import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/entities/reconstruction_job.dart';

void main() {
  test('domain terminality depends only on status, never raw progress', () {
    for (final status in ReconstructionStatus.values) {
      for (final progress in [-10, 0, 100, 10000]) {
        final job = ReconstructionJob(
          jobId: 'job',
          scanId: 'scan',
          inputImageId: 'image',
          status: status,
          stage: ReconstructionStage.uploading,
          progress: progress,
          execution: ReconstructionExecution.real,
          profile: 'opaque',
          retryCount: 7,
        );
        expect(job.progress, progress);
        expect(
          job.isTerminal,
          {
            ReconstructionStatus.done,
            ReconstructionStatus.failed,
            ReconstructionStatus.cancelled,
          }.contains(status),
        );
      }
    }
  });
}
