import 'dart:async';

import '../../../core/network/api_client.dart';
import 'api/reconstruction_api.dart';
import '../../../core/network/api_exception.dart';
import '../domain/entities/reconstruction_job.dart';
import '../domain/reconstruction_repository.dart';
import 'reconstruction_job_mapper.dart';

/// GET-only job observation. Errors never become backend job failures.
/// Observation failures are published separately from backend job updates.
class ReconstructionRepositoryImpl implements ReconstructionRepository {
  ReconstructionRepositoryImpl({
    required String scanId,
    ApiClient? apiClient,
    this.pollingInterval = const Duration(seconds: 3),
    this.maxBackoff = const Duration(seconds: 30),
    this.maxConsecutiveTransientFailures = 5,
  }) : _scanId = scanId,
       _api = ReconstructionApi(apiClient: apiClient) {
    if (scanId.isEmpty ||
        pollingInterval <= Duration.zero ||
        maxBackoff < pollingInterval ||
        maxConsecutiveTransientFailures < 1) {
      throw ArgumentError('Invalid polling configuration');
    }
    unawaited(_poll());
  }

  final String _scanId;
  final ReconstructionApi _api;
  final Duration pollingInterval;
  final Duration maxBackoff;
  final int maxConsecutiveTransientFailures;
  final _updates = StreamController<ReconstructionJob>.broadcast();
  final _errors = StreamController<ReconstructionObservationError>.broadcast();
  @override
  ReconstructionObservationError? lastObservationError;
  ReconstructionJob? _current;
  Timer? _timer;
  bool _stopped = false;
  bool _disposed = false;
  int _failures = 0;
  int _generation = 0;
  Future<void>? _pendingRequest;
  Future<void>? _retry;

  @override
  ReconstructionJob? get current => _current;
  @override
  Stream<ReconstructionJob> get jobs => _updates.stream;
  @override
  Stream<ReconstructionObservationError> get observationErrors =>
      _errors.stream;

  Future<void> _poll() {
    final pending = _performPoll(_generation);
    _pendingRequest = pending;
    return pending;
  }

  Future<void> _performPoll(int generation) async {
    if (_stopped) return;
    var delay = pollingInterval;
    try {
      final job = await _api.getJob(_scanId);
      if (_stopped || generation != _generation) return;
      if (job.scanId != _scanId) {
        throw const FormatException('Scan identity mismatch');
      }
      _current = mapReconstructionJob(job);
      lastObservationError = null;
      _failures = 0;
      _updates.add(_current!);
      if (_current!.isTerminal) _stopped = true;
    } catch (error) {
      if (_stopped || generation != _generation) return;
      var kind = switch (error) {
        FormatException() => ReconstructionObservationError.contract,
        ApiException(statusCode: 401) =>
          ReconstructionObservationError.authentication,
        ApiException(statusCode: 404) =>
          ReconstructionObservationError.unavailable,
        ApiException(statusCode: final code)
            when code <= 0 || code == 408 || code == 429 || code >= 500 =>
          ReconstructionObservationError.transient,
        ApiException() => ReconstructionObservationError.request,
        _ => ReconstructionObservationError.contract,
      };
      if (kind == ReconstructionObservationError.transient) {
        _failures++;
        if (_failures >= maxConsecutiveTransientFailures) {
          kind = ReconstructionObservationError.exhausted;
        }
      }
      lastObservationError = kind;
      _errors.add(kind);
      if (kind != ReconstructionObservationError.transient) {
        _stopped = true;
      } else {
        final micros =
            pollingInterval.inMicroseconds * (1 << _failures.clamp(1, 20));
        delay = Duration(
          microseconds: micros.clamp(1, maxBackoff.inMicroseconds),
        );
      }
    }
    if (!_stopped && generation == _generation) {
      _timer = Timer(delay, () => unawaited(_poll()));
    }
  }

  @override
  Future<void> retryObservation() {
    if (_disposed || _current?.isTerminal == true) return Future.value();
    return _retry ??= _restart().whenComplete(() => _retry = null);
  }

  Future<void> _restart() async {
    cancel();
    final generation = _generation;
    // Wait for an abandoned request to finish before starting another one.
    await _pendingRequest;
    if (_disposed || generation != _generation) return;
    _failures = 0;
    lastObservationError = null;
    _stopped = false;
    await _poll();
  }

  @override
  void cancel() {
    _generation++;
    _stopped = true;
    _timer?.cancel();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
    unawaited(_updates.close());
    unawaited(_errors.close());
  }
}
