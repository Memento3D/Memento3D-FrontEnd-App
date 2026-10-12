import 'dart:async';

import '../../domain/reconstruction_repository.dart';
import '../../domain/entities/reconstruction_job.dart';
import '../services/processing_progress_source.dart';
import '../models/processing_state.dart';
import '../models/reconstruction_job_presentation_mapper.dart';

/// Presentation adapter preserving the existing controller's local lifecycle.
class RepositoryProcessingProgressSource
    implements ProcessingProgressSource, ObservationProcessingProgressSource {
  RepositoryProcessingProgressSource(this._repository) {
    _listen();
  }
  final ReconstructionRepository _repository;
  final _updates = StreamController<ProcessingUpdate>.broadcast(sync: true);
  final _errors = StreamController<ProcessingObservationUpdate>.broadcast(
    sync: true,
  );
  late StreamSubscription<ReconstructionJob> _jobsSubscription;
  late StreamSubscription<ReconstructionObservationError> _errorSubscription;
  int _attempt = 0;
  bool _disposed = false;

  void _listen() {
    final attempt = _attempt;
    _jobsSubscription = _repository.jobs.listen((job) {
      if (!_disposed && attempt == _attempt) {
        _updates.add(ProcessingUpdate(attempt, presentReconstructionJob(job)));
      }
    });
    _errorSubscription = _repository.observationErrors.listen((error) {
      if (!_disposed && attempt == _attempt) {
        _errors.add(ProcessingObservationUpdate(attempt, error));
      }
    });
  }

  @override
  ProcessingUpdate get current => ProcessingUpdate(
    _attempt,
    _repository.current == null
        ? const ProcessingSnapshot.waiting()
        : presentReconstructionJob(_repository.current!),
  );

  @override
  Stream<ProcessingUpdate> get updates => _updates.stream;

  @override
  Stream<ProcessingObservationUpdate> get observationErrors => _errors.stream;
  @override
  ProcessingObservationUpdate? get currentObservationError =>
      _repository.lastObservationError == null
      ? null
      : ProcessingObservationUpdate(
          _attempt,
          _repository.lastObservationError!,
        );

  @override
  Future<void> retry(int attempt) async {
    if (_disposed) return;
    _attempt = attempt;
    await _jobsSubscription.cancel();
    await _errorSubscription.cancel();
    if (_disposed) return;
    _listen();
    await _repository.retryObservation();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_jobsSubscription.cancel());
    unawaited(_errorSubscription.cancel());
    _repository.dispose();
    unawaited(_updates.close());
    unawaited(_errors.close());
  }
}
