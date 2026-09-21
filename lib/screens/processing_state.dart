enum ProcessingStatus {
  readyToUpload,
  uploading,
  processing,
  completed,
  failed,
}

enum ProcessingStage {
  dataUpload,
  imagePreparation,
  structureReconstruction,
  detailGeneration,
  texturing,
  completion,
}

enum ProcessingStageStatus { pending, active, completed }

/// A future upload or job service can provide snapshots with measured progress.
/// The current production flow uses [ProcessingSnapshot.waiting] only.
class ProcessingSnapshot {
  const ProcessingSnapshot({
    required this.status,
    this.uploadedBytes,
    this.totalUploadBytes,
    this.jobId,
    this.stageStatuses = const {},
    this.progressPercent,
    this.errorMessage,
  });

  const ProcessingSnapshot.waiting()
    : status = ProcessingStatus.readyToUpload,
      uploadedBytes = null,
      totalUploadBytes = null,
      jobId = null,
      stageStatuses = const {},
      progressPercent = null,
      errorMessage = null;

  final ProcessingStatus status;
  final int? uploadedBytes;
  final int? totalUploadBytes;
  final String? jobId;
  final Map<ProcessingStage, ProcessingStageStatus> stageStatuses;
  final double? progressPercent;
  final String? errorMessage;

  bool get hasMeasuredProgress => progressPercent != null;

  ProcessingStageStatus statusFor(ProcessingStage stage) =>
      stageStatuses[stage] ?? ProcessingStageStatus.pending;
}
