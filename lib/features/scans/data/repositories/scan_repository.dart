import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

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

/// Repository managing user scan sessions
class ScanRepository {
  // Singleton pattern for simple state management across screens
  static final ScanRepository instance = ScanRepository._internal();
  ScanRepository._internal();

  final List<ScanItem> _scans = [];

  /// Get list of scans with optional filtering, search, and sorting
  List<ScanItem> getScans({
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'newest',
  }) {
    List<ScanItem> list = _scans.where((s) => s.status != ScanItemStatus.deleted).toList();

    // 1. Status Filter
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      switch (statusFilter) {
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
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

  /// Get storage quota metrics
  StorageQuota getStorageQuota() {
    final activeScans = _scans.where((s) => s.status != ScanItemStatus.deleted).toList();
    final totalUsed = activeScans.fold<int>(0, (sum, item) => sum + item.totalSizeBytes);
    const maxQuota = 10 * 1024 * 1024 * 1024; // 10 GB

    return StorageQuota(
      usedBytes: totalUsed,
      maxBytes: maxQuota,
      scanCount: activeScans.length,
    );
  }

  /// Get scan summary metrics
  Map<String, int> getSummaryMetrics() {
    final activeScans = _scans.where((s) => s.status != ScanItemStatus.deleted).toList();
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

  /// Create a new scan session
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
      description: description?.trim().isEmpty == true ? null : description?.trim(),
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

  /// Update scan name (FR-024)
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

  /// Soft-delete scan
  bool deleteScan(String id) {
    final index = _scans.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    _scans[index] = _scans[index].copyWith(
      status: ScanItemStatus.deleted,
      updatedAt: DateTime.now(),
    );
    return true;
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
}
