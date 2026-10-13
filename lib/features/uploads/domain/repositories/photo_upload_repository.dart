import '../entities/scan_image.dart';

/// Re-openable local input, independent of HTTP and platform picker packages.
abstract interface class PhotoUploadFile {
  String get filename;
  String? get mimeType;
  Future<int> length();
  Stream<List<int>> openRead();
}

abstract interface class PhotoUploadRepository {
  /// One non-idempotent POST. An ambiguous outcome must never be auto-replayed.
  Future<ScanImage> uploadPhoto({
    required String scanId,
    required PhotoUploadFile photo,
  });
}
