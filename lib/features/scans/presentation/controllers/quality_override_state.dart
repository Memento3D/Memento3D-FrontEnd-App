import '../../domain/models/quality_override_context.dart';

enum QualityOverrideStatus {
  unacknowledged,
  acknowledged,
  submitting,
  rejected,
  recoverableFailure,
  success,

  /// A previously successful run revisited without emitting success again.
  completed,
  ineligible,
}

/// Immutable snapshot. Only the controller constructs transitions.
final class QualityOverrideState {
  const QualityOverrideState({required this.context, required this.status});

  final QualityOverrideContext context;
  final QualityOverrideStatus status;

  bool get canAcknowledge =>
      context.isEligible && status == QualityOverrideStatus.unacknowledged;
  bool get canSubmit =>
      context.isEligible &&
      (status == QualityOverrideStatus.acknowledged ||
          status == QualityOverrideStatus.recoverableFailure);
  bool get isSubmitting => status == QualityOverrideStatus.submitting;
  bool get isBlocked =>
      status == QualityOverrideStatus.rejected ||
      status == QualityOverrideStatus.ineligible;
}
