const defaultReconstructionProfile = 'default';

/// Persisted backend job. Enum-like fields retain opaque backend values so a
/// future status, stage, or execution mode never breaks deserialization.
class ReconstructionJobRecord {
  const ReconstructionJobRecord({
    required this.jobId,
    required this.scanId,
    required this.inputImageId,
    required this.status,
    this.stage,
    required this.progress,
    required this.profile,
    required this.executionMode,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.errorCode,
    this.errorMessage,
    this.queuedAt,
    this.startedAt,
    this.completedAt,
  });

  final String jobId, scanId, inputImageId;
  final String status, profile, executionMode;
  final String? stage;
  final int progress, retryCount;
  final String? errorCode, errorMessage;
  final DateTime? queuedAt, startedAt, completedAt;
  final DateTime createdAt, updatedAt;
}
