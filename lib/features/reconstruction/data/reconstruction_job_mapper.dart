import '../domain/entities/reconstruction_job.dart';
import 'dto/reconstruction_job_dto.dart';

ReconstructionJob mapReconstructionJob(ReconstructionJobDto job) =>
    ReconstructionJob(
      status: switch (job.status) {
        ReconstructionJobStatus.queued => ReconstructionStatus.queued,
        ReconstructionJobStatus.running => ReconstructionStatus.running,
        ReconstructionJobStatus.done => ReconstructionStatus.done,
        ReconstructionJobStatus.failed => ReconstructionStatus.failed,
        ReconstructionJobStatus.cancelled => ReconstructionStatus.cancelled,
      },
      jobId: job.jobId,
      scanId: job.scanId,
      inputImageId: job.inputImageId,
      profile: job.profile,
      retryCount: job.retryCount,
      stage: switch (job.stage) {
        null => null,
        ReconstructionStageDto.downloading => ReconstructionStage.downloading,
        ReconstructionStageDto.preprocessing =>
          ReconstructionStage.preprocessing,
        ReconstructionStageDto.shapeGeneration =>
          ReconstructionStage.shapeGeneration,
        ReconstructionStageDto.texturing => ReconstructionStage.texturing,
        ReconstructionStageDto.validating => ReconstructionStage.validating,
        ReconstructionStageDto.exporting => ReconstructionStage.exporting,
        ReconstructionStageDto.uploading => ReconstructionStage.uploading,
      },
      progress: job.progress,
      execution: switch (job.executionMode) {
        ReconstructionExecutionMode.mock => ReconstructionExecution.mock,
        ReconstructionExecutionMode.real => ReconstructionExecution.real,
      },
      // Backend errors are retained in the DTO. No safe-message contract exists
      // for displaying arbitrary backend internals in the presentation layer.
    );
