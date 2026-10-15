import '../entities/scan_image.dart';
import '../repositories/photo_upload_repository.dart';

class PhotoUploadItem {
  const PhotoUploadItem({required this.localCaptureId, required this.file});
  final String localCaptureId;
  final PhotoUploadFile file;
}

class PhotoUploadManifest {
  PhotoUploadManifest({
    required this.id,
    required this.scanId,
    required List<PhotoUploadItem> items,
  }) : items = List.unmodifiable(items) {
    if (id.isEmpty ||
        scanId.trim().isEmpty ||
        items.isEmpty ||
        items.any((item) => item.localCaptureId.isEmpty) ||
        items.map((item) => item.localCaptureId).toSet().length !=
            items.length) {
      throw ArgumentError('A manifest needs a scan and unique, nonempty items');
    }
  }
  final String id, scanId;

  /// Frozen original order; position is never used as identity.
  final List<PhotoUploadItem> items;
}

class ConfirmedPhotoUpload {
  const ConfirmedPhotoUpload(this.item, this.image);
  final PhotoUploadItem item;
  final ScanImage image;
}

class PhotoUploadResult {
  PhotoUploadResult(this.manifest, List<ConfirmedPhotoUpload> photos)
    : photos = List.unmodifiable(photos);
  final PhotoUploadManifest manifest;
  String get scanId => manifest.scanId;
  final List<ConfirmedPhotoUpload> photos;
}
