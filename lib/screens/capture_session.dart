import 'dart:collection';

import 'package:camera/camera.dart';
import '../features/scans/data/services/scan_sync_manager.dart';

enum ReconstructionDetailLevel { standard, highDetail }

class CaptureSizeSummary {
  const CaptureSizeSummary(this.bytes, this.unavailableFiles);

  final int bytes;
  final int unavailableFiles;
}

class CaptureSession {
  final String? _initialScanId;
  String? _overrideScanId;
  final List<XFile> _capturedPhotos = [];
  ReconstructionDetailLevel detailLevel = ReconstructionDetailLevel.highDetail;

  CaptureSession({String? scanId}) : _initialScanId = scanId;

  String? get scanId {
    if (_overrideScanId != null) return _overrideScanId;
    if (_initialScanId != null) {
      return ScanSyncManager.instance.resolveId(_initialScanId);
    }
    return null;
  }

  void updateScanId(String newId) {
    _overrideScanId = newId;
  }

  UnmodifiableListView<XFile> get capturedPhotos =>
      UnmodifiableListView(_capturedPhotos);
  int get photoCount => _capturedPhotos.length;
  XFile? get latestPhoto =>
      _capturedPhotos.isEmpty ? null : _capturedPhotos.last;
  bool get canReview => _capturedPhotos.isNotEmpty;

  void addPhoto(XFile photo) => _capturedPhotos.add(photo);

  void removePhoto(XFile photo) => _capturedPhotos.remove(photo);

  Future<CaptureSizeSummary> measureSize() async {
    var bytes = 0;
    var unavailableFiles = 0;
    for (final photo in _capturedPhotos) {
      try {
        bytes += await photo.length();
      } catch (_) {
        unavailableFiles++;
      }
    }
    return CaptureSizeSummary(bytes, unavailableFiles);
  }
}
