import '../../domain/entities/reconstruction_job_record.dart';

bool isReconstructionUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

class ReconstructionJobRecordDto {
  const ReconstructionJobRecordDto._(this._job);
  final ReconstructionJobRecord _job;

  factory ReconstructionJobRecordDto.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a reconstruction job object');
    }
    String string(String key) {
      final field = value[key];
      if (field is! String || field.trim().isEmpty) {
        throw FormatException('Invalid $key');
      }
      return field;
    }

    String uuid(String key) {
      final field = string(key);
      if (!isReconstructionUuid(field)) throw FormatException('Invalid $key');
      return field;
    }

    int integer(String key) {
      final field = value[key];
      if (field is! int || field < 0) throw FormatException('Invalid $key');
      return field;
    }

    String? nullableString(String key) {
      final field = value[key];
      if (field == null) return null;
      if (field is! String) throw FormatException('Invalid $key');
      return field;
    }

    DateTime timestamp(String key) {
      final field = DateTime.tryParse(string(key));
      if (field == null) throw FormatException('Invalid $key');
      return field;
    }

    DateTime? nullableTimestamp(String key) =>
        value[key] == null ? null : timestamp(key);

    final progress = integer('progress');
    if (progress > 100) throw const FormatException('Invalid progress');
    return ReconstructionJobRecordDto._(
      ReconstructionJobRecord(
        jobId: uuid('job_id'),
        scanId: uuid('scan_id'),
        inputImageId: uuid('input_image_id'),
        status: string('status'),
        // A freshly queued job has no stage yet.
        stage: nullableString('stage'),
        progress: progress,
        profile: string('profile'),
        executionMode: string('execution_mode'),
        retryCount: integer('retry_count'),
        errorCode: nullableString('error_code'),
        errorMessage: nullableString('error_message'),
        queuedAt: nullableTimestamp('queued_at'),
        startedAt: nullableTimestamp('started_at'),
        completedAt: nullableTimestamp('completed_at'),
        createdAt: timestamp('created_at'),
        updatedAt: timestamp('updated_at'),
      ),
    );
  }

  ReconstructionJobRecord toDomain() => _job;
}
