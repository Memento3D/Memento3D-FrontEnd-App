import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/processing_state.dart';
import '../../domain/reconstruction_repository.dart';
import '../services/processing_progress_source.dart';
import '../adapters/repository_processing_progress_source.dart';

class ProcessingController extends ChangeNotifier {
  ProcessingController(ReconstructionRepository repository)
    : this.fromProgressSource(RepositoryProcessingProgressSource(repository));

  /// Presentation-only seam for deterministic fixtures and legacy UI tests.
  ProcessingController.fromProgressSource(ProcessingProgressSource source)
    : _source = source,
      _snapshot = source.current.snapshot,
      _attempt = source.current.attempt {
    _subscription = source.updates.listen(
      _accept,
      onError: (Object error) {
        if (!_disposed && !_snapshot.isTerminal) _sourceFailed();
      },
    );
    if (source is ObservationProcessingProgressSource) {
      final observations = source as ObservationProcessingProgressSource;
      _errorSubscription = observations.observationErrors.listen(
        _observationFailed,
      );
      final initialError = observations.currentObservationError;
      if (initialError != null) _observationFailed(initialError);
    }
  }
  final ProcessingProgressSource _source;
  late final StreamSubscription<ProcessingUpdate> _subscription;
  StreamSubscription<ProcessingObservationUpdate>? _errorSubscription;
  ProcessingSnapshot _snapshot;
  int _attempt;
  bool _retrying = false;
  bool _awaitingRetryState = false;
  bool _disposed = false;
  ProcessingSnapshot get snapshot => _snapshot;
  bool get isRetrying => _retrying;
  int get attempt => _attempt;

  void _observationFailed(ProcessingObservationUpdate update) {
    if (_disposed || update.attempt != _attempt || _snapshot.isTerminal) return;
    _snapshot = _snapshot.withObservationError(update.error);
    notifyListeners();
  }

  void _accept(ProcessingUpdate update) {
    if (_disposed ||
        update.attempt != _attempt ||
        (_snapshot.isTerminal && !_awaitingRetryState)) {
      return;
    }
    _awaitingRetryState = false;
    if (_snapshot == update.snapshot) return;
    _snapshot = update.snapshot;
    notifyListeners();
  }

  void _sourceFailed() {
    _awaitingRetryState = false;
    _snapshot = _snapshot.withObservationError(
      ReconstructionObservationError.request,
    );
    notifyListeners();
  }

  Future<void> retry() async {
    if (_disposed ||
        _retrying ||
        !(_snapshot.canRetryObservation ||
            (_snapshot.status == ProcessingStatus.failed &&
                _snapshot.canRetry))) {
      return;
    }
    _retrying = true;
    _awaitingRetryState = true;
    _attempt++;
    _snapshot = _snapshot.withObservationError(null);
    notifyListeners();
    try {
      await _source.retry(_attempt);
      _accept(_source.current);
      if (_source is ObservationProcessingProgressSource) {
        final error = (_source as ObservationProcessingProgressSource)
            .currentObservationError;
        if (error != null) _observationFailed(error);
      }
    } catch (_) {
      if (!_disposed) _sourceFailed();
    } finally {
      if (!_disposed) {
        _retrying = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(_errorSubscription?.cancel());
    _source.dispose();
    super.dispose();
  }
}
