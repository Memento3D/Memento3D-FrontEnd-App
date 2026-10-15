import '../features/scans/data/models/job_model.dart';

export '../features/scans/data/models/job_model.dart' show JobStage;

enum ProcessingStatus { waiting, running, completed, failed }

enum ProcessingStageStatus { pending, active, completed }

/// User-facing grouping of the 9 raw [JobStage] values into the 3 phases
/// shown on the Processing screen. Order and membership follow the real
/// backend pipeline order (`JobStage.index`) — it only groups adjacent
/// stages for display, it never reorders them.
enum ProcessingPhase { analyzing, modeling, finishing }

extension ProcessingPhaseMapping on ProcessingPhase {
  int get index => ProcessingPhase.values.indexOf(this);

  /// The [JobStage]s that belong to this phase, in pipeline order.
  List<JobStage> get stages => switch (this) {
    ProcessingPhase.analyzing => const [
      JobStage.downloading,
      JobStage.preprocessing,
    ],
    ProcessingPhase.modeling => const [JobStage.shapeGeneration],
    ProcessingPhase.finishing => const [
      JobStage.texturing,
      JobStage.validating,
      JobStage.exporting,
      JobStage.uploading,
    ],
  };
}

/// Which phase a raw backend stage belongs to. `queued` and `done` sit
/// outside the 3 displayed phases (before/after the pipeline runs).
ProcessingPhase? processingPhaseFor(JobStage? stage) {
  if (stage == null) return null;
  for (final phase in ProcessingPhase.values) {
    if (phase.stages.contains(stage)) return phase;
  }
  return null;
}

/// Snapshot consumed by the Processing screen.
/// Stage metadata and fallback progress come from [JobStage],
/// the single source of truth for the real backend pipeline order.
class ProcessingSnapshot {
  const ProcessingSnapshot({
    required this.status,
    required this.stage,
    required this.progress,
    this.etaSeconds,
    this.errorMessage,
  });

  const ProcessingSnapshot.waiting()
    : status = ProcessingStatus.waiting,
      stage = null,
      progress = null,
      etaSeconds = null,
      errorMessage = null;

  final ProcessingStatus status;
  final JobStage? stage;

  /// 0.0 - 1.0 when the backend (or deterministic fallback) provides it.
  final double? progress;
  final int? etaSeconds;
  final String? errorMessage;

  bool get hasMeasuredProgress => progress != null;

  ProcessingStageStatus statusFor(JobStage stage) {
    final currentIndex = this.stage?.index;
    if (status == ProcessingStatus.completed) {
      return ProcessingStageStatus.completed;
    }
    if (currentIndex == null) {
      return ProcessingStageStatus.pending;
    }
    if (stage.index < currentIndex) return ProcessingStageStatus.completed;
    if (stage.index == currentIndex) {
      return ProcessingStageStatus.active;
    }
    return ProcessingStageStatus.pending;
  }

  /// The phase the current raw stage falls into (for the "Bước N/3" label
  /// and the grouped history list). `null` while still queued.
  ProcessingPhase? get currentPhase {
    if (status == ProcessingStatus.completed) return ProcessingPhase.finishing;
    return processingPhaseFor(stage);
  }

  ProcessingStageStatus statusForPhase(ProcessingPhase phase) {
    if (status == ProcessingStatus.completed) {
      return ProcessingStageStatus.completed;
    }
    final current = currentPhase;
    if (current == null) return ProcessingStageStatus.pending;
    if (phase.index < current.index) return ProcessingStageStatus.completed;
    if (phase.index == current.index) return ProcessingStageStatus.active;
    return ProcessingStageStatus.pending;
  }
}
