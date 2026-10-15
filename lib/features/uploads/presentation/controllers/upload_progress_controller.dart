import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/upload_progress_snapshot.dart';
import '../../domain/repositories/upload_progress_source.dart';

/// Owns one attempt; the caller owns the source and the controller lifecycle.
class UploadProgressController extends ChangeNotifier {
  UploadProgressController({required this.source}) : _state = source.current {
    _subscription = source.snapshots.listen(
      _onSnapshot,
      onError: (Object error, StackTrace stackTrace) => _onSourceError(),
      onDone: _onSourceError,
    );
  }

  final UploadProgressSource source;
  late final StreamSubscription<UploadProgressSnapshot> _subscription;
  UploadProgressSnapshot _state;
  bool _disposed = false;
  bool _retryPending = false;
  bool _completionDelivered = false;
  int _revision = 0;

  UploadProgressSnapshot get state => _state;
  bool get canRetry => !_disposed && !_retryPending && state.canRetry;

  void _onSnapshot(UploadProgressSnapshot snapshot) {
    if (!_canAccept(snapshot)) return;
    _revision++;
    _accept(snapshot);
  }

  void _onSourceError() {
    if (_disposed || state.status == UploadProgressStatus.completed) return;
    _revision++;
    // An unprepared source has no upload to retry yet.
    if (state.totalUnits == 0) return;
    _emit(
      state.withStatus(
        UploadProgressStatus.recoverableFailure,
        failure: UploadFailure.sourceUnavailable,
      ),
    );
  }

  bool _canAccept(UploadProgressSnapshot snapshot) {
    if (_disposed || state.status == UploadProgressStatus.completed) {
      return false;
    }
    // Stable optional identity and a fixed unit manifest within this attempt.
    // Never let obsolete/less-confirmed results reset progress or change runs.
    if (snapshot.uploadIdentity != state.uploadIdentity ||
        (state.totalUnits != 0 && snapshot.totalUnits != state.totalUnits) ||
        snapshot.confirmedUnits < state.confirmedUnits ||
        (snapshot.acknowledgedBytes != null &&
            state.acknowledgedBytes != null &&
            snapshot.acknowledgedBytes! < state.acknowledgedBytes!)) {
      return false;
    }
    return true;
  }

  bool _accept(UploadProgressSnapshot snapshot) {
    if (!_canAccept(snapshot)) return false;
    _emit(snapshot);
    return true;
  }

  Future<void> retry() async {
    if (!canRetry) return;
    _retryPending = true;
    final revision = ++_revision;
    _emit(state.withStatus(UploadProgressStatus.reconciling));
    try {
      if (_disposed || revision != _revision) return;
      final snapshot = await source.retry();
      if (_disposed || revision != _revision) return;
      if (!_accept(snapshot)) {
        _emit(
          state.withStatus(
            UploadProgressStatus.recoverableFailure,
            failure: UploadFailure.sourceUnavailable,
          ),
        );
      }
    } catch (_) {
      if (_disposed || revision != _revision) return;
      _emit(
        state.withStatus(
          UploadProgressStatus.recoverableFailure,
          failure: UploadFailure.sourceUnavailable,
        ),
      );
    } finally {
      _retryPending = false;
      if (!_disposed && state.canRetry) notifyListeners();
    }
  }

  /// Shared across screen remounts for this attempt. Does not navigate or equate
  /// confirmed counts with completion; only an explicit completed snapshot can
  /// deliver the caller's Quality Check integration event.
  bool takeCompletion() {
    if (_disposed ||
        _completionDelivered ||
        state.status != UploadProgressStatus.completed) {
      return false;
    }
    _completionDelivered = true;
    return true;
  }

  void _emit(UploadProgressSnapshot snapshot) {
    _state = snapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
