enum UploadProgressStatus {
  preparing,
  uploading,
  waitingForNetwork,
  reconciling,
  completed,
  recoverableFailure,
}

enum UploadFailure { interrupted, sourceUnavailable }

enum UploadPhotoStatus { completed, current, pending }

/// Frontend snapshot, not a backend DTO. Units are opaque confirmed work;
/// their count does not imply photo count or any server chunk index base.
final class UploadProgressSnapshot {
  UploadProgressSnapshot({
    required this.status,
    required this.confirmedUnits,
    required this.totalUnits,
    this.acknowledgedBytes,
    this.totalBytes,
    this.bytesPerSecond,
    this.estimatedRemaining,
    this.uploadIdentity,
    this.supportsPersistentResume = false,
    this.failure,
    List<UploadPhotoStatus> photoStatuses = const [],
  }) : photoStatuses = List.unmodifiable(photoStatuses) {
    if (totalUnits < 0 || confirmedUnits < 0 || confirmedUnits > totalUnits) {
      throw ArgumentError('Invalid confirmed unit counts');
    }
    if (status != UploadProgressStatus.preparing && totalUnits == 0) {
      throw ArgumentError('An active upload needs a known nonzero unit total');
    }
    if (status == UploadProgressStatus.completed &&
        confirmedUnits != totalUnits) {
      throw ArgumentError('Completion requires all units confirmed');
    }
    if ((acknowledgedBytes != null && acknowledgedBytes! < 0) ||
        (totalBytes != null && totalBytes! < 0) ||
        (acknowledgedBytes != null &&
            totalBytes != null &&
            acknowledgedBytes! > totalBytes!)) {
      throw ArgumentError('Invalid byte counts');
    }
    if (bytesPerSecond != null &&
        (!bytesPerSecond!.isFinite || bytesPerSecond! < 0)) {
      throw ArgumentError('Invalid upload speed');
    }
    if (estimatedRemaining != null && estimatedRemaining!.isNegative) {
      throw ArgumentError('Invalid remaining time');
    }
    if (failure != null && status != UploadProgressStatus.recoverableFailure) {
      throw ArgumentError('Failure information requires a failure state');
    }
  }

  final UploadProgressStatus status;
  final int confirmedUnits;
  final int totalUnits;
  final int? acknowledgedBytes;
  final int? totalBytes;
  final double? bytesPerSecond;
  final Duration? estimatedRemaining;
  final String? uploadIdentity;
  final bool supportsPersistentResume;
  final UploadFailure? failure;

  /// Optional presentation mapping supplied by the source. Never inferred from
  /// chunk counts: one image may occupy multiple chunks or share a chunk.
  final List<UploadPhotoStatus> photoStatuses;

  double get confirmedProgress =>
      totalUnits == 0 ? 0 : confirmedUnits / totalUnits;
  double get progressPercent => confirmedProgress * 100;
  bool get canRetry => status == UploadProgressStatus.recoverableFailure;
  double? get visibleBytesPerSecond =>
      status == UploadProgressStatus.uploading ? bytesPerSecond : null;
  Duration? get visibleRemaining =>
      status == UploadProgressStatus.uploading ? estimatedRemaining : null;

  /// Local controller transition. Confirmed quantities remain unchanged.
  UploadProgressSnapshot withStatus(
    UploadProgressStatus next, {
    UploadFailure? failure,
  }) => UploadProgressSnapshot(
    status: next,
    confirmedUnits: confirmedUnits,
    totalUnits: totalUnits,
    acknowledgedBytes: acknowledgedBytes,
    totalBytes: totalBytes,
    uploadIdentity: uploadIdentity,
    supportsPersistentResume: supportsPersistentResume,
    failure: failure,
    photoStatuses: photoStatuses,
  );
}
