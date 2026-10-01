import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/processing_state.dart';
import '../services/processing_progress_source.dart';

class ProcessingController extends ChangeNotifier {
  ProcessingController(ProcessingProgressSource source)
    : _source = source,
      _snapshot = source.current.snapshot,
      _attempt = source.current.attempt {
    _subscription = source.updates.listen(
      _accept,
      onError: (Object error) {
        if (!_disposed && !_snapshot.isTerminal) _sourceFailed();
      },
    );
  }
  final ProcessingProgressSource _source;
  late final StreamSubscription<ProcessingUpdate> _subscription;
  ProcessingSnapshot _snapshot;
  int _attempt;
  bool _retrying = false;
  bool _awaitingRetryState = false;
  bool _disposed = false;
  ProcessingSnapshot get snapshot => _snapshot;
  bool get isRetrying => _retrying;
  int get attempt => _attempt;

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
    _snapshot = ProcessingSnapshot(
      status: ProcessingStatus.failed,
      stageStatuses: _snapshot.stageStatuses,
      progressPercent: _snapshot.progressPercent,
      provenance: _snapshot.provenance,
      uploadedBytes: _snapshot.uploadedBytes,
      totalUploadBytes: _snapshot.totalUploadBytes,
      jobId: _snapshot.jobId,
      failure: ProcessingFailure.sourceUnavailable,
      canRetry: _snapshot.canRetry,
    );
    notifyListeners();
  }

  Future<void> retry() async {
    if (_disposed ||
        _retrying ||
        _snapshot.status != ProcessingStatus.failed ||
        !_snapshot.canRetry) {
      return;
    }
    _retrying = true;
    _awaitingRetryState = true;
    _attempt++;
    notifyListeners();
    try {
      await _source.retry(_attempt);
      _accept(_source.current);
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
    _source.dispose();
    super.dispose();
  }
}
