enum ReconstructionStatus { queued, running, done, failed, cancelled }

enum ReconstructionStage {
  downloading,
  preprocessing,
  shapeGeneration,
  texturing,
  validating,
  exporting,
  uploading,
}

enum ReconstructionExecution { real, mock }

/// Observed job information, independent of transport and UI conventions.
/// Progress has unspecified units; only status determines terminality.
class ReconstructionJob {
  const ReconstructionJob({
    required this.jobId,
    required this.scanId,
    required this.inputImageId,
    required this.status,
    required this.stage,
    required this.progress,
    required this.execution,
    required this.profile,
    required this.retryCount,
  });

  final String jobId;
  final String scanId;
  final String inputImageId;
  final ReconstructionStatus status;
  final ReconstructionStage? stage;
  final int progress;
  final ReconstructionExecution execution;
  final String profile;
  final int retryCount;

  bool get isTerminal =>
      status == ReconstructionStatus.done ||
      status == ReconstructionStatus.failed ||
      status == ReconstructionStatus.cancelled;
}
