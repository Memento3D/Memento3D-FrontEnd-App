import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../data/models/scan_model.dart';
import '../../data/services/scan_service.dart';
import '../../data/services/scan_sync_manager.dart';

/// State management controller for 3D Scan Sessions conforming to Memento3D UI Blueprint
class ScanState extends ChangeNotifier {
  static final ScanState instance = ScanState();

  ScanService _scanService;

  List<ScanModel> _scans = [];
  String _selectedFilter =
      'all'; // 'all', 'draft', 'processing', 'done', 'failed'
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _lastErrorStatusCode;
  int _totalCount = 0;
  int _page = 1;
  int _totalPages = 1;

  // Maximum quota storage is 10 GB per FRONTEND_ARCHITECTURE.md
  static const int maxStorageBytes = 10 * 1024 * 1024 * 1024; // 10 GB in bytes

  ScanState({ScanService? scanService})
    : _scanService = scanService ?? ScanService();

  /// Setter for mock service in tests
  void setService(ScanService service) {
    _scanService = service;
  }

  // Getters
  List<ScanModel> get scans => List.unmodifiable(_scans);
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int? get lastErrorStatusCode => _lastErrorStatusCode;
  int get totalCount => _totalCount;
  int get page => _page;
  int get totalPages => _totalPages;

  /// Total storage used by user across all scans (in bytes)
  int get totalStorageBytes {
    return _scans.fold<int>(0, (sum, scan) => sum + scan.totalSizeBytes);
  }

  /// Storage usage ratio from 0.0 to 1.0
  double get storageUsageRatio {
    if (maxStorageBytes <= 0) return 0.0;
    final ratio = totalStorageBytes / maxStorageBytes;
    return ratio.clamp(0.0, 1.0);
  }

  /// Human-readable storage text, e.g. "1.2 GB / 10 GB"
  String get storageQuotaText {
    final usedGb = (totalStorageBytes / (1024 * 1024 * 1024)).toStringAsFixed(
      2,
    );
    return '$usedGb GB / 10 GB';
  }

  /// List of scans filtered by current status filter and search query
  List<ScanModel> get filteredScans {
    return _scans.where((scan) {
      // 1. Status Filter
      if (_selectedFilter != 'all') {
        if (scan.status.toLowerCase() != _selectedFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = scan.name.toLowerCase().contains(query);
        final matchesDesc =
            scan.description?.toLowerCase().contains(query) ?? false;
        final matchesNotes = scan.notes?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesDesc || matchesNotes;
      }

      return true;
    }).toList();
  }

  /// Set the active status filter ('all', 'draft', 'processing', 'done', 'failed')
  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Update the search keyword for client-side instant filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Fetch scan sessions from backend
  Future<void> loadScans({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _scanService.getAllScans();

      _scans = response.scans;
      _totalCount = response.totalCount;
      _page = response.page;
      _totalPages = response.totalPages;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phiên scan: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistically create a new scan session locally and sync to DB in background
  ScanModel createScanOptimistic({
    required String name,
    String? description,
    String? notes,
    String inputMode = 'image',
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticScan = ScanModel(
      id: tempId,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      inputMode: inputMode,
      status: 'draft',
      fileCount: 0,
      totalSizeBytes: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Prepend to current list immediately for instant user feedback
    _scans.insert(0, optimisticScan);
    _totalCount += 1;
    _errorMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    // Register sync start
    ScanSyncManager.instance.registerSyncStart(
      tempId,
      onRetry: () => _syncOptimisticScanToDb(optimisticScan),
    );

    // Fire & forget background DB sync
    _syncOptimisticScanToDb(optimisticScan);

    return optimisticScan;
  }

  /// Background database sync for optimistic scan
  Future<void> _syncOptimisticScanToDb(ScanModel optimisticScan) async {
    try {
      final serverScan = await _scanService.createScan(
        name: optimisticScan.name,
        description: optimisticScan.description,
        notes: optimisticScan.notes,
        inputMode: optimisticScan.inputMode,
      );

      // Reconcile client list with real DB record
      final index = _scans.indexWhere((s) => s.id == optimisticScan.id);
      if (index != -1) {
        _scans[index] = serverScan;
      } else {
        _scans.removeWhere((s) => s.id == serverScan.id);
        _scans.insert(0, serverScan);
      }

      _errorMessage = null;
      _lastErrorStatusCode = null;
      ScanSyncManager.instance.registerSyncSuccess(
        tempId: optimisticScan.id,
        realId: serverScan.id,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _handleOptimisticSyncFailure(optimisticScan, e.message, e.statusCode);
    } catch (e) {
      final mappedMessage = ErrorMapper.map(rawMessage: e.toString());
      _handleOptimisticSyncFailure(optimisticScan, mappedMessage, null);
    }
  }

  void _handleOptimisticSyncFailure(
    ScanModel optimisticScan,
    String errorMsg,
    int? statusCode,
  ) {
    // Rollback optimistic item from list
    _scans.removeWhere((s) => s.id == optimisticScan.id);
    _totalCount = (_totalCount - 1).clamp(0, 999999);
    _errorMessage = errorMsg;
    _lastErrorStatusCode = statusCode;
    notifyListeners();

    // Register failure event
    ScanSyncManager.instance.registerSyncFailure(
      tempId: optimisticScan.id,
      errorMessage: errorMsg,
      statusCode: statusCode,
    );

    // Throw user-friendly error notification
    if (statusCode == 403) {
      AppMessenger.showQuotaExceededDialog();
    } else {
      AppMessenger.showError(
        'Không thể lưu phiên scan "${optimisticScan.name}" lên máy chủ: $errorMsg. Đã hoàn tác phiên scan.',
        onRetry: () => _syncOptimisticScanToDb(optimisticScan),
      );
    }
  }

  /// Create a new scan session (US-005, FR-005) - Synchronous or Awaitable
  Future<ScanModel?> createScan({
    required String name,
    String? description,
    String? notes,
    String inputMode = 'image',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    try {
      final newScan = await _scanService.createScan(
        name: name,
        description: description,
        notes: notes,
        inputMode: inputMode,
      );

      // Prepend to current list
      _scans.insert(0, newScan);
      _totalCount += 1;
      _errorMessage = null;
      _lastErrorStatusCode = null;
      return newScan;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _lastErrorStatusCode = e.statusCode;
      return null;
    } catch (e) {
      _errorMessage = ErrorMapper.map(rawMessage: e.toString());
      _lastErrorStatusCode = null;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update editable scan session details (FR-024)
  Future<bool> updateScan(
    String id, {
    String? name,
    String? description,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedScan = await _scanService.updateScan(
        id,
        name: name,
        description: description,
        notes: notes,
      );

      final index = _scans.indexWhere((s) => s.id == id);
      if (index != -1) {
        _scans[index] = updatedScan;
      }
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật phiên scan: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete a scan session (FR-035)
  Future<bool> deleteScan(String id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _scanService.deleteScan(id);
      _scans.removeWhere((s) => s.id == id);
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Không thể xóa phiên scan: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Reset internal state (useful on logout)
  void clear() {
    _scans = [];
    _selectedFilter = 'all';
    _searchQuery = '';
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    _totalCount = 0;
    _page = 1;
    _totalPages = 1;
    notifyListeners();
  }
}
