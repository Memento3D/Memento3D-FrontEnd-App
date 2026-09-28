import 'dart:async';

/// Status of the background database sync for a 3D scan session
enum ScanSyncState {
  /// Scan has been created optimistically on client, POST request is in flight
  syncing,

  /// Scan record successfully committed to Backend database with a permanent ID
  synced,

  /// Backend DB commit failed (rolled back from client list)
  failed,
}

/// Event emitted when a scan session changes sync status
class ScanSyncEvent {
  final String tempId;
  final String? realId;
  final ScanSyncState state;
  final String? errorMessage;
  final int? statusCode;

  const ScanSyncEvent({
    required this.tempId,
    this.realId,
    required this.state,
    this.errorMessage,
    this.statusCode,
  });

  bool get isSuccess => state == ScanSyncState.synced;
  bool get isFailed => state == ScanSyncState.failed;
  bool get isSyncing => state == ScanSyncState.syncing;
}

/// Central manager orchestrating optimistic scan creation,
/// background DB synchronization, ID remapping, and failure notifications.
class ScanSyncManager {
  static final ScanSyncManager instance = ScanSyncManager._internal();
  ScanSyncManager._internal();

  final _eventController = StreamController<ScanSyncEvent>.broadcast();

  /// Mapping from temporary client-generated scan ID to permanent backend ID
  final Map<String, String> _tempToRealIdMap = {};

  /// Current sync state by temporary/scan ID
  final Map<String, ScanSyncState> _statusMap = {};

  /// Optional retry handlers to resubmit failed creations
  final Map<String, Future<void> Function()> _retryHandlers = {};

  /// Global broadcast stream of all sync events
  Stream<ScanSyncEvent> get syncStream => _eventController.stream;

  /// Stream of sync events specifically for a given scan (temp or real ID)
  Stream<ScanSyncEvent> watchScan(String scanId) {
    return _eventController.stream.where(
      (event) => event.tempId == scanId || event.realId == scanId,
    );
  }

  /// Resolves the canonical/real ID if the provided ID was a temporary ID that has synced
  String resolveId(String? id) {
    if (id == null) return '';
    return _tempToRealIdMap[id] ?? id;
  }

  /// Check current sync state for a given ID
  ScanSyncState getStatus(String id) {
    return _statusMap[id] ?? ScanSyncState.synced;
  }

  /// Register an optimistic scan session creation start
  void registerSyncStart(String tempId, {Future<void> Function()? onRetry}) {
    _statusMap[tempId] = ScanSyncState.syncing;
    if (onRetry != null) {
      _retryHandlers[tempId] = onRetry;
    }

    _eventController.add(
      ScanSyncEvent(
        tempId: tempId,
        state: ScanSyncState.syncing,
      ),
    );
  }

  /// Register successful sync to backend database
  void registerSyncSuccess({
    required String tempId,
    required String realId,
  }) {
    _tempToRealIdMap[tempId] = realId;
    _statusMap[tempId] = ScanSyncState.synced;
    _statusMap[realId] = ScanSyncState.synced;
    _retryHandlers.remove(tempId);

    _eventController.add(
      ScanSyncEvent(
        tempId: tempId,
        realId: realId,
        state: ScanSyncState.synced,
      ),
    );
  }

  /// Register failed sync to backend database
  void registerSyncFailure({
    required String tempId,
    required String errorMessage,
    int? statusCode,
  }) {
    _statusMap[tempId] = ScanSyncState.failed;

    _eventController.add(
      ScanSyncEvent(
        tempId: tempId,
        state: ScanSyncState.failed,
        errorMessage: errorMessage,
        statusCode: statusCode,
      ),
    );
  }

  /// Attempt to retry saving the scan to DB
  Future<bool> retrySync(String tempId) async {
    final handler = _retryHandlers[tempId];
    if (handler != null) {
      _statusMap[tempId] = ScanSyncState.syncing;
      _eventController.add(
        ScanSyncEvent(tempId: tempId, state: ScanSyncState.syncing),
      );
      try {
        await handler();
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Clear all cached mappings and status (e.g. on logout or test cleanup)
  void clear() {
    _tempToRealIdMap.clear();
    _statusMap.clear();
    _retryHandlers.clear();
  }
}
