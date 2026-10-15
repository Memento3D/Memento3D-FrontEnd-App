import '../entities/reconstruction_job_record.dart';

abstract interface class ReconstructionJobStartRepository {
  /// One non-idempotent start. Throws a typed ReconstructionStartFailure.
  Future<ReconstructionJobRecord> startJob({
    required String scanId,
    required String inputImageId,
    String profile = defaultReconstructionProfile,
  });

  /// Explicit read capability for later reconciliation; never starts a job.
  /// Throws a typed ReconstructionFetchFailure.
  Future<ReconstructionJobRecord> getLatestJob({required String scanId});
}
