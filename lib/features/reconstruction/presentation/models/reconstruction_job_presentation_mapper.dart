import '../../domain/entities/reconstruction_job.dart';
import 'processing_state.dart';

ProcessingSnapshot presentReconstructionJob(ReconstructionJob job) =>
    ProcessingSnapshot(
      isBackendObservation: true,
      status: switch (job.status) {
        ReconstructionStatus.queued => ProcessingStatus.queued,
        ReconstructionStatus.running => ProcessingStatus.processing,
        ReconstructionStatus.done => ProcessingStatus.completed,
        ReconstructionStatus.failed => ProcessingStatus.failed,
        ReconstructionStatus.cancelled => ProcessingStatus.cancelled,
      },
      jobId: job.jobId,
      jobStage: switch (job.stage) {
        null => null,
        ReconstructionStage.downloading => ProcessingJobStage.downloading,
        ReconstructionStage.preprocessing => ProcessingJobStage.preprocessing,
        ReconstructionStage.shapeGeneration =>
          ProcessingJobStage.shapeGeneration,
        ReconstructionStage.texturing => ProcessingJobStage.texturing,
        ReconstructionStage.validating => ProcessingJobStage.validating,
        ReconstructionStage.exporting => ProcessingJobStage.exporting,
        ReconstructionStage.uploading => ProcessingJobStage.uploading,
      },
      backendProgress: job.progress,
      provenance: job.execution == ReconstructionExecution.mock
          ? ProgressProvenance.simulated
          : ProgressProvenance.measured,
    );
