import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/dto/reconstruction_job_dto.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/reconstruction_job_mapper.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/entities/reconstruction_job.dart';

Map<String, dynamic> response() => {
  'job_id': '12345678-1234-1234-1234-123456789abc',
  'scan_id': '22345678-1234-1234-1234-123456789abc',
  'input_image_id': '32345678-1234-1234-1234-123456789abc',
  'status': 'running',
  'stage': 'uploading',
  'progress': 10000,
  'execution_mode': 'real',
  'profile': 'opaque',
  'retry_count': 7,
  'error_code': null,
  'error_message': null,
  'queued_at': null,
  'started_at': null,
  'completed_at': null,
  'created_at': null,
  'updated_at': null,
};

void main() {
  test('DTO maps to independent domain statuses and preserves identities', () {
    final statuses = {
      'queued': ReconstructionStatus.queued,
      'running': ReconstructionStatus.running,
      'done': ReconstructionStatus.done,
      'failed': ReconstructionStatus.failed,
      'cancelled': ReconstructionStatus.cancelled,
    };
    for (final entry in statuses.entries) {
      final dto = ReconstructionJobDto.fromJson(
        response()..['status'] = entry.key,
      );
      final ReconstructionJob job = mapReconstructionJob(dto);
      expect(job, isNot(isA<ReconstructionJobDto>()));
      expect(job.status, entry.value);
      expect(job.jobId, dto.jobId);
      expect(job.scanId, dto.scanId);
      expect(job.inputImageId, dto.inputImageId);
      expect(job.profile, dto.profile);
      expect(job.retryCount, 7);
      expect(job.progress, 10000);
    }
  });

  test('every wire stage maps explicitly to a domain stage', () {
    final stages = {
      'downloading': ReconstructionStage.downloading,
      'preprocessing': ReconstructionStage.preprocessing,
      'shape_generation': ReconstructionStage.shapeGeneration,
      'texturing': ReconstructionStage.texturing,
      'validating': ReconstructionStage.validating,
      'exporting': ReconstructionStage.exporting,
      'uploading': ReconstructionStage.uploading,
    };
    for (final entry in stages.entries) {
      final job = mapReconstructionJob(
        ReconstructionJobDto.fromJson(response()..['stage'] = entry.key),
      );
      expect(job.stage, entry.value);
      expect(job.status, ReconstructionStatus.running);
    }
  });

  test('execution provenance is preserved without DTO enum dependence', () {
    for (final mode in ['real', 'mock']) {
      final job = mapReconstructionJob(
        ReconstructionJobDto.fromJson(response()..['execution_mode'] = mode),
      );
      expect(
        job.execution,
        mode == 'real'
            ? ReconstructionExecution.real
            : ReconstructionExecution.mock,
      );
    }
  });
}
