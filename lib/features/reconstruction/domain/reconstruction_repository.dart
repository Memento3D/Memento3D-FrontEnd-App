import 'entities/reconstruction_job.dart';

/// Observation failures are distinct from the job's own failed status.
enum ReconstructionObservationError {
  authentication,
  unavailable,
  contract,
  transient,
  request,
}

/// One exclusively owned observation session for an already-started scan job.
/// Construction may begin observation immediately. No job creation or restart.
abstract interface class ReconstructionRepository {
  ReconstructionJob? get current;
  Stream<ReconstructionJob> get jobs;
  ReconstructionObservationError? get lastObservationError;
  Stream<ReconstructionObservationError> get observationErrors;
  void cancel();
  void dispose();
}
