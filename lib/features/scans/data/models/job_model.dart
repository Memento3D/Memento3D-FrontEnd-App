/// Real backend processing stages, in pipeline order.
enum JobStage {
  queued,
  extracting,
  detecting,
  matching,
  sfm,
  mvs,
  meshing,
  texturing,
  repairing,
  exporting,
  done,
}

JobStage? jobStageFromBackendValue(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
  for (final stage in JobStage.values) {
    if (stage.name == normalized) return stage;
  }
  return null;
}

enum JobStatus {
  queued,
  running,
  done,
  failed,
  unknown;

  static JobStatus fromBackendValue(String? value) {
    if (value == null) return JobStatus.unknown;
    switch (value.trim().toLowerCase()) {
      case 'queued':
      case 'pending':
        return JobStatus.queued;
      case 'processing':
      case 'running':
      case 'in_progress':
        return JobStatus.running;
      case 'done':
      case 'completed':
      case 'success':
        return JobStatus.done;
      case 'failed':
      case 'error':
        return JobStatus.failed;
      default:
        return JobStatus.unknown;
    }
  }
}

/// Job payload returned by the backend.
class JobModel {
  final String id;
  final String? scanId;
  final JobStatus status;
  final JobStage? stage;
  final double? progress; // 0.0 - 1.0
  final int? etaSeconds;
  final String? errorMessage;

  const JobModel({
    required this.id,
    this.scanId,
    required this.status,
    this.stage,
    this.progress,
    this.etaSeconds,
    this.errorMessage,
  });

  bool get isDone => status == JobStatus.done;
  bool get isFailed => status == JobStatus.failed;

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: (json['job_id'] ?? json['jobId'] ?? json['id'] ?? '').toString(),
      scanId: (json['scan_id'] ?? json['scanId'])?.toString(),
      status: JobStatus.fromBackendValue(
        (json['status'] ?? json['job_status'])?.toString(),
      ),
      stage: jobStageFromBackendValue(
        (json['stage'] ?? json['current_stage'])?.toString(),
      ),
      progress: _parseProgress(json),
      etaSeconds: _parseEta(json),
      errorMessage:
          (json['error_message'] ?? json['errorMessage'] ?? json['error'])
              ?.toString(),
    );
  }

  static double? _parseProgress(Map<String, dynamic> json) {
    final raw =
        json['progress'] ?? json['progress_pct'] ?? json['progress_percent'];
    if (raw is num) {
      final value = raw.toDouble();
      return value > 1.0 ? value / 100.0 : value;
    }
    if (raw is String) {
      final parsed = double.tryParse(raw.replaceAll('%', ''));
      if (parsed != null) {
        return parsed > 1.0 ? parsed / 100.0 : parsed;
      }
    }
    return null;
  }

  static int? _parseEta(Map<String, dynamic> json) {
    final raw =
        json['eta_seconds'] ??
        json['etaSeconds'] ??
        json['estimated_time_seconds'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
