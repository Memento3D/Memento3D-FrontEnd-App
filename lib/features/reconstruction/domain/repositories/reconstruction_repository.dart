import '../entities/reconstruction_job.dart';

abstract interface class ReconstructionRepository {
  /// One non-idempotent start. Throws a typed ReconstructionStartFailure.
  Future<ReconstructionJob> startJob({
    required String scanId,
    required String inputImageId,
    String profile = defaultReconstructionProfile,
  });

  /// Explicit read capability for later reconciliation; never starts a job.
  /// Throws a typed ReconstructionFetchFailure.
  Future<ReconstructionJob> getLatestJob({required String scanId});
}
