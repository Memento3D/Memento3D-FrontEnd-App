import 'package:flutter/foundation.dart';

import '../../domain/reconstruction_repository.dart';

enum ProcessingStatus {
  observationLoading,
  readyToUpload,
  uploading,
  processing,
  completed,
  failed,
  queued,
  cancelled,
}

/// Reconstruction pipeline stages, separate from the legacy local/demo stages.
enum ProcessingJobStage {
  downloading,
  preprocessing,
  shapeGeneration,
  texturing,
  validating,
  exporting,
  uploading,
}

/// Frontend presentation stages only, never backend wire values.
/// Do not serialize these names or assume backend mappings.
enum ProcessingStage {
  dataUpload,
  imagePreparation,
  structureReconstruction,
  detailGeneration,
  texturing,
  completion,
}

enum ProcessingStageStatus { pending, active, completed }

enum ProgressProvenance { unknown, simulated, measured }

/// Local presentation failures, not backend error codes.
enum ProcessingFailure { simulated, sourceUnavailable }

@immutable
class ProcessingSnapshot {
  ProcessingSnapshot({
    required this.status,
    this.uploadedBytes,
    this.totalUploadBytes,
    this.jobId,
    Map<ProcessingStage, ProcessingStageStatus> stageStatuses = const {},
    this.progressPercent,
    this.errorMessage,
    this.provenance = ProgressProvenance.unknown,
    this.failure,
    this.canRetry = false,
    this.jobStage,
    this.backendProgress,
    this.observationError,
    this.isBackendObservation = false,
  }) : assert(
         progressPercent == null ||
             (progressPercent.isFinite &&
                 progressPercent >= 0 &&
                 progressPercent <= 100),
       ),
       stageStatuses = Map.unmodifiable(stageStatuses);

  const ProcessingSnapshot.waiting()
    : status = ProcessingStatus.readyToUpload,
      uploadedBytes = null,
      totalUploadBytes = null,
      jobId = null,
      stageStatuses = const {},
      progressPercent = null,
      errorMessage = null,
      provenance = ProgressProvenance.unknown,
      failure = null,
      canRetry = false,
      jobStage = null,
      backendProgress = null,
      observationError = null,
      isBackendObservation = false;

  const ProcessingSnapshot.observing()
    : status = ProcessingStatus.observationLoading,
      uploadedBytes = null,
      totalUploadBytes = null,
      jobId = null,
      stageStatuses = const {},
      progressPercent = null,
      errorMessage = null,
      provenance = ProgressProvenance.unknown,
      failure = null,
      canRetry = false,
      jobStage = null,
      backendProgress = null,
      observationError = null,
      isBackendObservation = true;

  final bool isBackendObservation;
  final ProcessingStatus status;
  final int? uploadedBytes;
  final int? totalUploadBytes;
  final String? jobId;
  final Map<ProcessingStage, ProcessingStageStatus> stageStatuses;
  final double? progressPercent;
  final String? errorMessage;

  final ProgressProvenance provenance;
  final ProcessingFailure? failure;
  final bool canRetry;
  final ProcessingJobStage? jobStage;
  final int? backendProgress;
  final ReconstructionObservationError? observationError;

  ProcessingSnapshot withObservationError(
    ReconstructionObservationError? error,
  ) => ProcessingSnapshot(
    status: status,
    uploadedBytes: uploadedBytes,
    totalUploadBytes: totalUploadBytes,
    jobId: jobId,
    stageStatuses: stageStatuses,
    progressPercent: progressPercent,
    errorMessage: errorMessage,
    provenance: provenance,
    failure: failure,
    canRetry: canRetry,
    jobStage: jobStage,
    backendProgress: backendProgress,
    observationError: error,
    isBackendObservation: isBackendObservation,
  );

  bool get canRetryObservation =>
      !isTerminal &&
      observationError != null &&
      observationError != ReconstructionObservationError.transient &&
      observationError != ReconstructionObservationError.authentication;

  bool get hasKnownProgress =>
      provenance != ProgressProvenance.unknown && progressPercent != null;
  bool get hasMeasuredProgress =>
      provenance == ProgressProvenance.measured && progressPercent != null;
  bool get isRunning =>
      status == ProcessingStatus.processing ||
      status == ProcessingStatus.uploading;
  bool get isTerminal =>
      status == ProcessingStatus.completed ||
      status == ProcessingStatus.failed ||
      status == ProcessingStatus.cancelled;

  @override
  bool operator ==(Object other) =>
      other is ProcessingSnapshot &&
      isBackendObservation == other.isBackendObservation &&
      status == other.status &&
      uploadedBytes == other.uploadedBytes &&
      totalUploadBytes == other.totalUploadBytes &&
      jobId == other.jobId &&
      progressPercent == other.progressPercent &&
      provenance == other.provenance &&
      errorMessage == other.errorMessage &&
      failure == other.failure &&
      canRetry == other.canRetry &&
      jobStage == other.jobStage &&
      backendProgress == other.backendProgress &&
      observationError == other.observationError &&
      mapEquals(stageStatuses, other.stageStatuses);

  @override
  int get hashCode => Object.hash(
    isBackendObservation,
    status,
    uploadedBytes,
    totalUploadBytes,
    jobId,
    progressPercent,
    provenance,
    errorMessage,
    failure,
    canRetry,
    jobStage,
    backendProgress,
    observationError,
    Object.hashAllUnordered(
      stageStatuses.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  ProcessingStageStatus statusFor(ProcessingStage stage) =>
      stageStatuses[stage] ?? ProcessingStageStatus.pending;
}
