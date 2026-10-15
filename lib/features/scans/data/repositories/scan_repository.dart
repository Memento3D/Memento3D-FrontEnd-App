import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/core/utils/app_messenger.dart';
import 'package:memento3d_frontend_app/core/utils/error_mapper.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_model.dart'
    show ReconstructionJobModel;
import 'package:memento3d_frontend_app/features/scans/data/models/scan_output_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_service.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_sync_manager.dart';

class StorageQuota {
  final int usedBytes;
  final int maxBytes;
  final int scanCount;

  const StorageQuota({
    required this.usedBytes,
    required this.maxBytes,
    required this.scanCount,
  });

  double get percentage => (usedBytes / maxBytes).clamp(0.0, 1.0);

  String get formattedUsed {
    if (usedBytes < 1024 * 1024 * 1024) {
      return '${(usedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedMax => '10 GB';
}

/// Repository managing user scan sessions via Backend CRUD API with local cache
class ScanRepository {
  // Singleton pattern for state management across screens
  static final ScanRepository instance = ScanRepository._internal();
  ScanRepository._internal({ScanService? scanService})
    : _scanService = scanService ?? ScanService();

  ScanService _scanService;

  /// Allow injecting a mock ScanService in unit tests
  void setService(ScanService service) {
    _scanService = service;
  }

  final List<ScanItem> _scans = [];

  List<ScanItem> get cachedScans => List.unmodifiable(_scans);
  List<ScanItem> get scans => cachedScans;

  /// Fetch scans from backend API (GET /api/v1/scans)
  Future<List<ScanItem>> fetchScans({
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'newest',
    bool refresh = false,
  }) async {
    final apiSort = ScanService.normalizeSort(sortBy);
    final apiStatus = ScanService.normalizeStatus(statusFilter);

    final response = await _scanService.getAllScans(
      status: apiStatus,
      sort: apiSort,
    );

    final items = response.scans.map((m) => ScanItem.fromScanModel(m)).toList();

    _scans.clear();
    _scans.addAll(items);

    return getScans(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      sortBy: sortBy,
    );
  }

  /// Get list of scans with optional filtering, search, and sorting (from cache)
  List<ScanItem> getScans({
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'newest',
  }) {
    List<ScanItem> list = _scans
        .where((s) => s.status != ScanItemStatus.deleted)
        .toList();

    // 1. Status Filter
    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'all') {
      switch (statusFilter.toLowerCase()) {
        case 'done':
          list = list.where((s) => s.status == ScanItemStatus.done).toList();
          break;
        case 'processing':
          list = list.where((s) => s.isProcessing).toList();
          break;
        case 'failed':
          list = list.where((s) => s.status == ScanItemStatus.failed).toList();
          break;
        case 'draft':
          list = list.where((s) => s.status == ScanItemStatus.draft).toList();
          break;
      }
    }

    // 2. Search Query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final nameMatch = s.name.toLowerCase().contains(query);
        final descMatch = s.description?.toLowerCase().contains(query) ?? false;
        final notesMatch = s.notes?.toLowerCase().contains(query) ?? false;
        return nameMatch || descMatch || notesMatch;
      }).toList();
    }

    // 3. Sorting
    switch (sortBy) {
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'name_asc':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'size_desc':
        list.sort((a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes));
        break;
      case 'newest':
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  /// Create a new scan session optimistically on client, sync to DB in background
  ScanItem createScanOptimistic({
    required String name,
    required ScanInputMode inputMode,
    String? description,
    String? notes,
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticScan = ScanItem(
      id: tempId,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      inputMode: inputMode,
      status: ScanItemStatus.draft,
      fileCount: 0,
      totalSizeBytes: 0,
      createdAt: DateTime.now(),
    );

    _scans.removeWhere((s) => s.id == optimisticScan.id);
    _scans.insert(0, optimisticScan);

    // Register sync start
    ScanSyncManager.instance.registerSyncStart(
      tempId,
      onRetry: () => _syncOptimisticScanToDb(optimisticScan),
    );

    // Fire and forget background DB sync
    _syncOptimisticScanToDb(optimisticScan);

    return optimisticScan;
  }

  Future<void> _syncOptimisticScanToDb(ScanItem optimisticScan) async {
    try {
      final scanModel = await _scanService.createScan(
        name: optimisticScan.name,
        inputMode: optimisticScan.inputMode.name,
        description: optimisticScan.description,
        notes: optimisticScan.notes,
      );

      final realItem = ScanItem.fromScanModel(scanModel);
      final index = _scans.indexWhere((s) => s.id == optimisticScan.id);
      if (index != -1) {
        _scans[index] = realItem;
      } else {
        _scans.removeWhere((s) => s.id == realItem.id);
        _scans.insert(0, realItem);
      }

      ScanSyncManager.instance.registerSyncSuccess(
        tempId: optimisticScan.id,
        realId: realItem.id,
      );
    } on ApiException catch (e) {
      _handleOptimisticSyncFailure(optimisticScan, e.message, e.statusCode);
    } catch (e) {
      final mappedMessage = ErrorMapper.map(rawMessage: e.toString());
      _handleOptimisticSyncFailure(optimisticScan, mappedMessage, null);
    }
  }

  void _handleOptimisticSyncFailure(
    ScanItem optimisticScan,
    String errorMsg,
    int? statusCode,
  ) {
    _scans.removeWhere((s) => s.id == optimisticScan.id);

    ScanSyncManager.instance.registerSyncFailure(
      tempId: optimisticScan.id,
      errorMessage: errorMsg,
      statusCode: statusCode,
    );

    if (statusCode == 403) {
      AppMessenger.showQuotaExceededDialog();
    } else {
      AppMessenger.showError(
        'Không thể lưu phiên scan "${optimisticScan.name}" lên máy chủ: $errorMsg. Đã hoàn tác phiên scan.',
        onRetry: () => _syncOptimisticScanToDb(optimisticScan),
      );
    }
  }

  /// Create a new scan session via Backend API (POST /api/v1/scans)
  Future<ScanItem> createScanAsync({
    required String name,
    required ScanInputMode inputMode,
    String? description,
    String? notes,
  }) async {
    final scanModel = await _scanService.createScan(
      name: name,
      inputMode: inputMode.name,
      description: description,
      notes: notes,
    );

    final item = ScanItem.fromScanModel(scanModel);
    _scans.removeWhere((s) => s.id == item.id);
    _scans.insert(0, item);
    return item;
  }

  /// Create a new scan session (synchronous version for local tests/mocking)
  ScanItem createScan({
    required String name,
    required ScanInputMode inputMode,
    String? description,
    String? notes,
  }) {
    final newId = 'scan-${DateTime.now().millisecondsSinceEpoch}';
    final newScan = ScanItem(
      id: newId,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      inputMode: inputMode,
      status: ScanItemStatus.draft,
      fileCount: 0,
      totalSizeBytes: 0,
      createdAt: DateTime.now(),
    );

    _scans.insert(0, newScan);
    return newScan;
  }

  /// Get scan session details by ID via Backend API (GET /api/v1/scans/{id})
  Future<ScanItem> getScanByIdAsync(String id) async {
    final scanModel = await _scanService.getScanById(id);
    final item = ScanItem.fromScanModel(scanModel);
    final index = _scans.indexWhere((s) => s.id == id);
    if (index != -1) {
      _scans[index] = item;
    } else {
      _scans.insert(0, item);
    }
    return item;
  }

  /// Update scan metadata via Backend API (PATCH /api/v1/scans/{id})
  Future<ScanItem?> updateScanAsync(
    String id, {
    String? name,
    String? description,
    String? notes,
  }) async {
    final scanModel = await _scanService.updateScan(
      id,
      name: name,
      description: description,
      notes: notes,
    );
    final item = ScanItem.fromScanModel(scanModel);
    final index = _scans.indexWhere((s) => s.id == id);
    if (index != -1) {
      _scans[index] = item;
    }
    return item;
  }

  /// Update scan name via Backend API (PATCH /api/v1/scans/{id})
  Future<ScanItem?> updateScanNameAsync(String id, String newName) {
    return updateScanAsync(id, name: newName);
  }

  /// Synchronous update scan name (for tests/local state)
  ScanItem? updateScanName(String id, String newName) {
    final index = _scans.indexWhere((s) => s.id == id);
    if (index == -1) return null;

    final updated = _scans[index].copyWith(
      name: newName.trim(),
      updatedAt: DateTime.now(),
    );
    _scans[index] = updated;
    return updated;
  }

  /// Submit reconstruction job for a scan via Backend API (POST /api/v1/scans/{id}/job)
  /// (US-027, FR-081, FR-082, FR-199). Marks the cached scan as "processing" on success
  /// so the dashboard reflects the new state without an extra round-trip.
  Future<ReconstructionJobModel> submitReconstructionJobAsync(
    String scanId,
  ) async {
    final job = await _scanService.createReconstructionJob(scanId);

    final index = _scans.indexWhere((s) => s.id == scanId);
    if (index != -1) {
      _scans[index] = _scans[index].copyWith(status: ScanItemStatus.processing);
    }

    return job;
  }

  /// Delete scan via Backend API (DELETE /api/v1/scans/{id})
  Future<bool> deleteScanAsync(String id) async {
    await _scanService.deleteScan(id);
    _scans.removeWhere((s) => s.id == id);
    return true;
  }

  /// Soft-delete scan (synchronous for tests/local state)
  bool deleteScan(String id) {
    final index = _scans.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    _scans.removeWhere((s) => s.id == id);
    return true;
  }

  /// Get generated output files (GLB, OBJ, ...) via Backend API (GET /api/v1/scans/{id}/outputs)
  Future<ScanOutputsResponseModel> getScanOutputsAsync(String id) {
    return _scanService.getScanOutputs(id);
  }

  /// Retry a failed scan
  ScanItem? retryScan(String id) {
    final index = _scans.indexWhere((s) => s.id == id);
    if (index == -1) return null;

    final retried = _scans[index].copyWith(
      status: ScanItemStatus.processing,
      progress: 0.1,
      errorMessage: null,
      updatedAt: DateTime.now(),
    );
    _scans[index] = retried;
    return retried;
  }

  /// Get storage quota metrics
  StorageQuota getStorageQuota() {
    final activeScans = _scans
        .where((s) => s.status != ScanItemStatus.deleted)
        .toList();
    final totalUsed = activeScans.fold<int>(
      0,
      (sum, item) => sum + item.totalSizeBytes,
    );
    const maxQuota = 10 * 1024 * 1024 * 1024; // 10 GB

    return StorageQuota(
      usedBytes: totalUsed,
      maxBytes: maxQuota,
      scanCount: activeScans.length,
    );
  }

  /// Get scan summary metrics
  Map<String, int> getSummaryMetrics() {
    final activeScans = _scans
        .where((s) => s.status != ScanItemStatus.deleted)
        .toList();
    int doneCount = 0;
    int processingCount = 0;
    int failedCount = 0;

    for (final scan in activeScans) {
      if (scan.isDone) doneCount++;
      if (scan.isProcessing) processingCount++;
      if (scan.isFailed) failedCount++;
    }

    return {
      'total': activeScans.length,
      'done': doneCount,
      'processing': processingCount,
      'failed': failedCount,
    };
  }

  /// Clear in-memory scans (useful on logout)
  void clear() {
    _scans.clear();
  }
}
