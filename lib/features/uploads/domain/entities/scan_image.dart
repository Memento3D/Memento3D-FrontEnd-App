/// Confirmed backend ScanImage; local paths are never persisted identities.
class ScanImage {
  const ScanImage({
    required this.id,
    required this.scanId,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.format,
    required this.sortOrder,
    required this.uploadStatus,
    required this.isExcluded,
    required this.needsQualityCheck,
    required this.createdAt,
    this.excludeReason,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  final String id, scanId, originalFilename, mimeType, format, uploadStatus;
  final int fileSizeBytes, sortOrder;
  final bool isExcluded, needsQualityCheck;
  final DateTime createdAt;
  final String? excludeReason, thumbnailPath;
  final int? width, height;
}
