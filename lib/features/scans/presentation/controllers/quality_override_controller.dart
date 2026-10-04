import 'package:flutter/foundation.dart';

import '../../domain/models/quality_override_context.dart';
import '../../domain/models/quality_override_outcome.dart';
import '../../domain/repositories/quality_override_repository.dart';
import 'quality_override_state.dart';

class QualityOverrideController extends ChangeNotifier {
  QualityOverrideController({
    required this.repository,
    required QualityOverrideContext context,
  }) : _state = QualityOverrideState(
         context: context,
         status: context.isEligible
             ? QualityOverrideStatus.unacknowledged
             : QualityOverrideStatus.ineligible,
       );

  final QualityOverrideRepository repository;
  final Map<(String, String), QualityOverrideStatus> _terminalRuns = {};
  final Set<(String, String)> _pendingRuns = {};
  QualityOverrideState _state;
  int _generation = 0;
  bool _disposed = false;

  QualityOverrideState get state => _state;

  /// Allows an open acknowledgement sheet to detect replaced or disposed input.
  int get contextRevision => _generation;

  /// Every replacement invalidates acknowledgement, including the same run.
  void updateContext(QualityOverrideContext context) {
    if (_disposed) return;
    _generation++;
    _emit(
      context,
      !context.isEligible
          ? QualityOverrideStatus.ineligible
          : _terminalRuns[(context.scanId, context.qualityRunId)] ??
                QualityOverrideStatus.unacknowledged,
    );
  }

  void acknowledge() {
    if (_disposed || !state.canAcknowledge) return;
    _emit(state.context, QualityOverrideStatus.acknowledged);
  }

  /// Calling this again after a recoverable failure is an explicit retry.
  Future<void> submit() async {
    if (_disposed || !state.canSubmit || !state.context.isEligible) return;
    final context = state.context;
    final run = (context.scanId, context.qualityRunId);
    if (_pendingRuns.contains(run) || _terminalRuns.containsKey(run)) return;
    final generation = _generation;
    // Set the guard before notifying listeners or invoking the repository.
    _pendingRuns.add(run);
    _emit(context, QualityOverrideStatus.submitting);
    if (_disposed || generation != _generation) {
      _pendingRuns.remove(run);
      return;
    }

    QualityOverrideOutcome outcome;
    try {
      outcome = await repository.requestOverride(context);
    } catch (_) {
      // Unexpected adapter failures are recoverable without exposing details.
      outcome = QualityOverrideOutcome.recoverableFailure;
    }
    _pendingRuns.remove(run);
    if (_disposed) return;

    final status = switch (outcome) {
      QualityOverrideOutcome.success => QualityOverrideStatus.success,
      QualityOverrideOutcome.rejected => QualityOverrideStatus.rejected,
      QualityOverrideOutcome.recoverableFailure =>
        QualityOverrideStatus.recoverableFailure,
    };
    if (status == QualityOverrideStatus.success ||
        status == QualityOverrideStatus.rejected) {
      _terminalRuns[run] = status == QualityOverrideStatus.success
          ? QualityOverrideStatus.completed
          : status;
    }
    if (generation != _generation) {
      // A revisited rejected run must block immediately. Other stale outcomes
      // still cannot affect the current UI or emit a success continuation.
      final currentContext = state.context;
      if (status == QualityOverrideStatus.rejected &&
          (currentContext.scanId, currentContext.qualityRunId) == run) {
        _emit(currentContext, QualityOverrideStatus.rejected);
      }
      return;
    }
    _emit(context, status);
  }

  void _emit(QualityOverrideContext context, QualityOverrideStatus status) {
    _state = QualityOverrideState(context: context, status: status);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
