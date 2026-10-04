import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models/job_model.dart';
import '../../data/services/job_service.dart';
import '../../data/services/job_socket.dart';

enum ProcessingViewStatus { loading, running, reconnecting, completed, failed }

JobModel jobModelFromSocketMessage(String message) {
  final decoded = jsonDecode(message);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid job payload');
  }

  Map<String, dynamic> payload = decoded;
  final event = (decoded['event'] ?? decoded['type'])?.toString();
  if (decoded['data'] is Map<String, dynamic>) {
    payload = decoded['data'] as Map<String, dynamic>;
  } else if (decoded['payload'] is Map<String, dynamic>) {
    payload = decoded['payload'] as Map<String, dynamic>;
  }

  switch (event) {
    case 'job_completed':
    case 'completed':
      payload = {...payload, 'status': 'done'};
      break;
    case 'job_failed':
    case 'failed':
      payload = {...payload, 'status': 'failed'};
      break;
    case 'stage_changed':
      payload = {...payload, 'status': payload['status'] ?? 'processing'};
      break;
    case 'progress_update':
      payload = {...payload, 'status': payload['status'] ?? 'processing'};
      break;
  }
  return JobModel.fromJson(payload);
}

/// Drives the Processing Progress screen:
/// WebSocket primary, 5s polling fallback, explicit lifecycle states.
class ProcessingProgressController extends ChangeNotifier {
  ProcessingProgressController({
    required this.scanId,
    JobService? jobService,
    JobSocketFactory? socketFactory,
    this.onDone,
    this.onFailed,
    this.pollingInterval = const Duration(seconds: 5),
    this.wsReconnectDelay = const Duration(seconds: 2),
  }) : _jobService = jobService ?? JobService(),
       _socketFactory = socketFactory ?? connectJobSocket;

  final String scanId;
  final JobService _jobService;
  final JobSocketFactory _socketFactory;
  final VoidCallback? onDone;
  final VoidCallback? onFailed;
  final Duration pollingInterval;
  final Duration wsReconnectDelay;

  ProcessingViewStatus _status = ProcessingViewStatus.loading;
  JobModel? _job;
  String? _errorMessage;
  bool _disposed = false;
  bool _terminalNotified = false;

  JobSocket? _socket;
  StreamSubscription<String>? _socketSubscription;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  bool _polling = false;
  bool _usingWebSocket = false;
  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 3;

  ProcessingViewStatus get status => _status;
  JobModel? get job => _job;
  String? get errorMessage => _errorMessage;
  bool get isUsingPollingFallback => _polling;

  double get progress => _job?.effectiveProgress ?? 0.0;
  JobStage? get stage => _job?.stage;
  String? get rawStage => _job?.rawStage;
  int? get etaSeconds => _job?.etaSeconds;

  Future<void> start() async {
    _status = ProcessingViewStatus.loading;
    notifyListeners();
    try {
      final job = await _jobService.getScanJob(scanId);
      _applyJob(job);
      if (_job?.isTerminal == true) return;
    } catch (e, st) {
      debugPrint('ProcessingProgressController initial GET failed: $e\n$st');
      _errorMessage = e.toString();
    }
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    if (_disposed || (_job?.isTerminal ?? false)) return;
    try {
      final socket = await _socketFactory(scanId);
      if (_disposed || (_job?.isTerminal ?? false)) {
        await socket.close();
        return;
      }
      _socket = socket;
      _usingWebSocket = true;
      _reconnectAttempts = 0;
      _status = _job == null
          ? ProcessingViewStatus.loading
          : ProcessingViewStatus.running;
      _errorMessage = null;
      _stopPolling();
      notifyListeners();
      _socketSubscription = socket.messages.listen(
        (message) {
          try {
            _applyJob(jobModelFromSocketMessage(message));
          } catch (e) {
            debugPrint('Malformed job message ignored: $e');
          }
        },
        onError: (Object e) => _handleSocketDisconnect(),
        onDone: () => _handleSocketDisconnect(),
      );
    } catch (e) {
      debugPrint('WebSocket connect failed, using polling: $e');
      _handleSocketDisconnect();
    }
  }

  void _handleSocketDisconnect() {
    _usingWebSocket = false;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    if (_disposed || (_job?.isTerminal ?? false)) return;
    _status = ProcessingViewStatus.reconnecting;
    notifyListeners();
    _startPolling();
    // Guarded reconnect attempts; polling keeps the UI live meanwhile.
    _reconnectTimer?.cancel();
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer = Timer(wsReconnectDelay, () async {
        if (_disposed || (_job?.isTerminal ?? false) || _usingWebSocket) return;
        await _connectSocket();
      });
    }
  }

  void _startPolling() {
    if (_polling || _disposed || (_job?.isTerminal ?? false)) return;
    _polling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollingInterval, (_) => _pollOnce());
    _pollOnce();
  }

  void _stopPolling() {
    _polling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_disposed || (_job?.isTerminal ?? false)) {
      _stopPolling();
      return;
    }
    try {
      final job = await _jobService.getScanJob(scanId);
      if (_disposed) return;
      _applyJob(job);
    } catch (e) {
      debugPrint('Polling GET failed: $e');
    }
  }

  void _applyJob(JobModel job) {
    _job = job;
    if (job.isDone) {
      _status = ProcessingViewStatus.completed;
      _stopPolling();
      _reconnectTimer?.cancel();
      _closeSocket();
      notifyListeners();
      if (!_terminalNotified) {
        _terminalNotified = true;
        onDone?.call();
      }
      return;
    }
    if (job.isFailed) {
      _status = ProcessingViewStatus.failed;
      _errorMessage = job.errorMessage;
      _stopPolling();
      _reconnectTimer?.cancel();
      _closeSocket();
      notifyListeners();
      if (!_terminalNotified) {
        _terminalNotified = true;
        onFailed?.call();
      }
      return;
    }
    // Healthy data means WebSocket (or polling) is providing updates;
    // a healthy socket lets us drop the polling fallback.
    if (_usingWebSocket) {
      _stopPolling();
    }
    _status = ProcessingViewStatus.running;
    notifyListeners();
  }

  void _closeSocket() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    _usingWebSocket = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    _reconnectTimer?.cancel();
    _closeSocket();
    super.dispose();
  }
}
