import '../../presentation/models/processing_state.dart';
import 'reconstruction_job_response.dart';

ProcessingSnapshot mapReconstructionJob(ReconstructionJobResponse job) =>
    ProcessingSnapshot(
      status: switch (job.status) {
        ReconstructionJobStatus.queued => ProcessingStatus.queued,
        ReconstructionJobStatus.running => ProcessingStatus.processing,
        ReconstructionJobStatus.done => ProcessingStatus.completed,
        ReconstructionJobStatus.failed => ProcessingStatus.failed,
        ReconstructionJobStatus.cancelled => ProcessingStatus.cancelled,
      },
      jobId: job.jobId,
      jobStage: switch (job.stage) {
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
      provenance: job.executionMode == ReconstructionExecutionMode.mock
          ? ProgressProvenance.simulated
          : ProgressProvenance.measured,
      // Backend errors are retained in the DTO. No safe-message contract exists
      // for displaying arbitrary backend internals in the presentation layer.
    );
