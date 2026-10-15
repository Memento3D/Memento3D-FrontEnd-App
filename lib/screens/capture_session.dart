import 'dart:collection';
import 'dart:math';

import 'package:camera/camera.dart';

enum ReconstructionDetailLevel { standard, highDetail }

class CaptureSizeSummary {
  const CaptureSizeSummary(this.bytes, this.unavailableFiles);

  final int bytes;
  final int unavailableFiles;
}

class CapturedPhoto {
  CapturedPhoto(this.file)
    : localCaptureId =
          'capture-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  final String localCaptureId;
  final XFile file;
}

class CaptureSession {
  /// Omit only for local previews; persisted capture callers supply the server ID.
  CaptureSession({this.scanId}) {
    if (scanId != null && scanId!.trim().isEmpty) {
      throw ArgumentError.value(scanId, 'scanId', 'Must not be empty');
    }
  }

  /// Backend-created identity, preserved verbatim. Never derived from photos.
  final String? scanId;

  final List<XFile> _capturedPhotos = [];
  final List<CapturedPhoto> _entries = [];
  List<CapturedPhoto> get photoEntries => List.unmodifiable(_entries);
  ReconstructionDetailLevel detailLevel = ReconstructionDetailLevel.highDetail;

  UnmodifiableListView<XFile> get capturedPhotos =>
      UnmodifiableListView(_capturedPhotos);
  int get photoCount => _capturedPhotos.length;
  XFile? get latestPhoto =>
      _capturedPhotos.isEmpty ? null : _capturedPhotos.last;
  bool get canReview => _capturedPhotos.isNotEmpty;

  void addPhoto(XFile photo) {
    _capturedPhotos.add(photo);
    _entries.add(CapturedPhoto(photo));
  }

  void removePhoto(XFile photo) {
    final index = _capturedPhotos.indexOf(photo);
    if (index < 0) return;
    _capturedPhotos.removeAt(index);
    _entries.removeAt(index);
  }

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
