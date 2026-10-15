/// Real backend processing stages, in pipeline order.
/// Keep values in sync with the backend `ReconstructionStage` enum
/// (see memeto3D/.../entity/ReconstructionStage.java). `queued` and
/// `done` are pseudo-stages bracketing the real pipeline so the UI can
/// show a full step list even though the backend only ever sends the
/// 7 stages in between.
enum JobStage {
  queued,
  downloading,
  preprocessing,
  shapeGeneration,
  texturing,
  validating,
  exporting,
  uploading,
  done,
}

extension JobStageParsing on JobStage {
  /// Index of the stage inside the real pipeline order (0-based).
  int get index => JobStage.values.indexOf(this);

  /// Deterministic fallback progress (0.0 - 1.0) derived from the
  /// real stage order. Used only when the backend omits progress.
  double get fallbackProgress =>
      JobStage.values.length == 1 ? 1.0 : index / (JobStage.values.length - 1);

  /// Snake_case value as sent by the backend (matches
  /// `ReconstructionStage` for the 7 real stages).
  String get backendValue => switch (this) {
    JobStage.shapeGeneration => 'shape_generation',
    _ => name,
  };
}

/// Parse a backend stage string. Returns null for unknown values so
/// the UI can degrade gracefully instead of crashing.
JobStage? jobStageFromBackendValue(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
  for (final stage in JobStage.values) {
    if (stage.backendValue == normalized) return stage;
  }
  // Common aliases from payloads / logs
  switch (normalized) {
    case 'download':
      return JobStage.downloading;
    case 'preprocess':
      return JobStage.preprocessing;
    case 'shape':
    case 'generation':
    case 'mesh_generation':
    case 'meshing':
      return JobStage.shapeGeneration;
    case 'validate':
    case 'validation':
    case 'qc':
      return JobStage.validating;
    case 'export':
      return JobStage.exporting;
    case 'upload':
      return JobStage.uploading;
    case 'complete':
    case 'completed':
      return JobStage.done;
    default:
      return null;
  }
}

/// Real job status values coming from the backend.
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
      case 'cancelled':
      case 'canceled':
        return JobStatus.failed;
      default:
        return JobStatus.unknown;
    }
  }
}

/// Job progress payload returned by the backend.
class JobModel {
  final String id;
  final String? scanId;
  final JobStatus status;
  final JobStage? stage;
  final String? rawStage;
  final double? progress; // 0.0 - 1.0
  final int? etaSeconds;
  final String? errorMessage;

  const JobModel({
    required this.id,
    this.scanId,
    required this.status,
    this.stage,
    this.rawStage,
    this.progress,
    this.etaSeconds,
    this.errorMessage,
  });

  bool get isDone => status == JobStatus.done;
  bool get isFailed => status == JobStatus.failed;
  bool get isTerminal => isDone || isFailed;

  /// Effective progress: backend value when present, deterministic
  /// stage-based fallback otherwise.
  double get effectiveProgress {
    if (progress != null) return progress!.clamp(0.0, 1.0);
    if (isDone) return 1.0;
    return stage?.fallbackProgress ?? 0.0;
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final rawStage =
        (json['stage'] ?? json['current_stage'] ?? json['currentStage'])
            ?.toString();
    return JobModel(
      id: (json['job_id'] ?? json['jobId'] ?? json['id'] ?? '').toString(),
      scanId: (json['scan_id'] ?? json['scanId'] ?? json['scan'])?.toString(),
      status: JobStatus.fromBackendValue(
        (json['status'] ?? json['job_status'] ?? json['jobStatus'])?.toString(),
      ),
      stage: jobStageFromBackendValue(rawStage),
      rawStage: rawStage,
      progress: _parseProgress(json),
      etaSeconds: _parseEta(json),
      errorMessage:
          (json['error_message'] ?? json['errorMessage'] ?? json['error'])
              ?.toString(),
    );
  }

  static double? _parseProgress(Map<String, dynamic> json) {
    final raw =
        json['progress'] ??
        json['progress_pct'] ??
        json['progressPct'] ??
        json['progress_percent'];
    // The reconstruction response contract uses integer percentages, including
    // 1 meaning 1%, not a completed job.
    if (json.containsKey('execution_mode') ||
        json.containsKey('input_image_id')) {
      final percent = raw is num ? raw.toDouble() : double.tryParse('$raw');
      return percent == null ? null : (percent / 100).clamp(0.0, 1.0);
    }
    if (raw is num) {
      final value = raw.toDouble();
      // Accept both 0..1 fractions and 0..100 percentages.
      return value > 1.0 ? (value / 100.0).clamp(0.0, 1.0) : value;
    }
    if (raw is String) {
      final parsed = double.tryParse(raw.replaceAll('%', ''));
      if (parsed != null) {
        return parsed > 1.0 ? (parsed / 100.0).clamp(0.0, 1.0) : parsed;
      }
    }
    return null;
  }

  static int? _parseEta(Map<String, dynamic> json) {
    final raw =
        json['eta_seconds'] ??
        json['etaSeconds'] ??
        json['estimated_time_seconds'] ??
        json['estimatedTimeSeconds'] ??
        json['estimated_remaining_seconds'];
    if (raw is num) return raw.toInt().clamp(0, 1 << 30);
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
