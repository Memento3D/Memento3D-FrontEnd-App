import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../presentation/models/processing_state.dart';
import '../../presentation/services/processing_progress_source.dart';
import '../models/reconstruction_job_mapper.dart';
import '../models/reconstruction_job_response.dart';

enum ProcessingObservationError {
  authentication,
  unavailable,
  contract,
  transient,
  request,
}

/// GET-only job observation. Errors never become backend job failures.
/// Phase 2 must consume [observationErrors] separately from snapshot updates.
class HttpProcessingProgressSource implements ProcessingProgressSource {
  HttpProcessingProgressSource({
    required String scanId,
    ApiClient? apiClient,
    this.pollingInterval = const Duration(seconds: 3),
    this.maxBackoff = const Duration(seconds: 30),
  }) : _scanId = scanId,
       _apiClient = apiClient ?? ApiClient() {
    if (scanId.isEmpty ||
        pollingInterval <= Duration.zero ||
        maxBackoff < pollingInterval) {
      throw ArgumentError('Invalid polling configuration');
    }
    unawaited(_poll());
  }

  final String _scanId;
  final ApiClient _apiClient;
  final Duration pollingInterval;
  final Duration maxBackoff;
  final _updates = StreamController<ProcessingUpdate>.broadcast();
  final _errors = StreamController<ProcessingObservationError>.broadcast();
  ProcessingObservationError? lastObservationError;
  ProcessingUpdate _current = const ProcessingUpdate(
    0,
    ProcessingSnapshot.waiting(),
  );
  Timer? _timer;
  bool _stopped = false;
  bool _disposed = false;
  int _failures = 0;

  @override
  ProcessingUpdate get current => _current;
  @override
  Stream<ProcessingUpdate> get updates => _updates.stream;
  Stream<ProcessingObservationError> get observationErrors => _errors.stream;

  Future<void> _poll() async {
    if (_stopped) return;
    var delay = pollingInterval;
    try {
      final response = await _apiClient.get(
        '${ApiConfig.scans}/${Uri.encodeComponent(_scanId)}/job',
      );
      if (_stopped) return;
      final job = ReconstructionJobResponse.fromJson(response);
      if (job.scanId != _scanId) {
        throw const FormatException('Scan identity mismatch');
      }
      _current = ProcessingUpdate(0, mapReconstructionJob(job));
      lastObservationError = null;
      _failures = 0;
      _updates.add(_current);
      if (_current.snapshot.isTerminal) _stopped = true;
    } catch (error) {
      if (_stopped) return;
      final kind = switch (error) {
        FormatException() => ProcessingObservationError.contract,
        ApiException(statusCode: 401) =>
          ProcessingObservationError.authentication,
        ApiException(statusCode: 404) => ProcessingObservationError.unavailable,
        ApiException(statusCode: final code)
            when code <= 0 || code == 408 || code == 429 || code >= 500 =>
          ProcessingObservationError.transient,
        ApiException() => ProcessingObservationError.request,
        _ => ProcessingObservationError.contract,
      };
      lastObservationError = kind;
      _errors.add(kind);
      if (kind != ProcessingObservationError.transient) {
        _stopped = true;
      } else {
        _failures = (_failures + 1).clamp(1, 20);
        final micros = pollingInterval.inMicroseconds * (1 << _failures);
        delay = Duration(
          microseconds: micros.clamp(1, maxBackoff.inMicroseconds),
        );
      }
    }
    if (!_stopped) _timer = Timer(delay, () => unawaited(_poll()));
  }

  /// This source cannot restart reconstruction; GET refresh is not job retry.
  @override
  Future<void> retry(int attempt) =>
      Future.error(UnsupportedError('Reconstruction retry is unavailable'));

  void cancel() {
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
