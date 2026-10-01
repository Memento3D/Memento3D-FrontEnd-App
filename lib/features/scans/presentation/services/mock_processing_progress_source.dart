import 'dart:async';

import '../models/processing_state.dart';
import 'processing_progress_source.dart';

enum MockProcessingScenario { success, failure, unknown }

/// Manual finite fixtures: no timers, randomness or transport.
class MockProcessingProgressSource implements ProcessingProgressSource {
  MockProcessingProgressSource({
    this.scenario = MockProcessingScenario.success,
  }) {
    _current = ProcessingUpdate(0, _snapshot());
  }
  final MockProcessingScenario scenario;
  final _updates = StreamController<ProcessingUpdate>.broadcast(sync: true);
  late ProcessingUpdate _current;
  int _step = 0;
  bool _failed = false;
  bool _disposed = false;
  @override
  ProcessingUpdate get current => _current;
  @override
  Stream<ProcessingUpdate> get updates => _updates.stream;

  ProcessingSnapshot _snapshot() => ProcessingSnapshot(
    status: _failed
        ? ProcessingStatus.failed
        : _step == 5
        ? ProcessingStatus.completed
        : ProcessingStatus.processing,
    // Five equally weighted reconstruction stages, excluding upload. This mock
    // convention does not represent real processing time or measured work.
    progressPercent: scenario == MockProcessingScenario.unknown
        ? null
        : _step / 5 * 100,
    provenance: scenario == MockProcessingScenario.unknown
        ? ProgressProvenance.unknown
        : ProgressProvenance.simulated,
    stageStatuses: {
      for (var i = 0; i < ProcessingStage.values.length; i++)
        ProcessingStage.values[i]: i <= _step
            ? ProcessingStageStatus.completed
            : i == _step + 1
            ? ProcessingStageStatus.active
            : ProcessingStageStatus.pending,
    },
    failure: _failed ? ProcessingFailure.simulated : null,
    canRetry: _failed,
  );

  void advance() {
    if (_disposed || current.snapshot.isTerminal) return;
    if (scenario == MockProcessingScenario.failure && _step == 2) {
      _failed = true;
    } else {
      _step++;
    }
    _publish(current.attempt);
  }

  void _publish(int attempt) {
    _current = ProcessingUpdate(attempt, _snapshot());
    _updates.add(_current);
  }

  @override
  Future<void> retry(int attempt) async {
    if (_disposed || !current.snapshot.canRetry) return;
    _step = 0;
    _failed = false;
    _publish(attempt);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_updates.close());
  }
}
