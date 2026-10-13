import '../../domain/entities/scan_image.dart';

bool isBackendUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

class ScanImageDto {
  ScanImageDto._(
    this.id,
    this.scanId,
    this.originalFilename,
    this.fileSizeBytes,
    this.mimeType,
    this.format,
    this.sortOrder,
    this.uploadStatus,
    this.isExcluded,
    this.needsQualityCheck,
    this.createdAt,
    this.excludeReason,
    this.thumbnailPath,
    this.width,
    this.height,
  );

  final String id, scanId, originalFilename, mimeType, format, uploadStatus;
  final int fileSizeBytes, sortOrder;
  final bool isExcluded, needsQualityCheck;
  final DateTime createdAt;
  final String? excludeReason, thumbnailPath;
  final int? width, height;

  factory ScanImageDto.fromJson(Object? value) {
    final json = _object(value);
    String uuid(String key) {
      final result = _string(json, key);
      if (!isBackendUuid(result)) throw FormatException('Invalid $key');
      return result;
    }

    bool boolean(String key) {
      if (json[key] is! bool) throw FormatException('Invalid $key');
      return json[key] as bool;
    }

    String? optionalString(String key) {
      if (json[key] == null) return null;
      return _string(json, key, nonempty: false);
    }

    int? optionalInt(String key) =>
        json[key] == null ? null : _integer(json, key);
    final timestamp = _string(json, 'created_at');
    final createdAt = DateTime.tryParse(timestamp);
    if (createdAt == null ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(timestamp)) {
      throw const FormatException('Invalid created_at');
    }
    return ScanImageDto._(
      uuid('id'),
      uuid('scan_id'),
      _string(json, 'original_filename'),
      _integer(json, 'file_size_bytes'),
      _string(json, 'mime_type'),
      _string(json, 'format'),
      _integer(json, 'sort_order'),
      _string(json, 'upload_status'),
      boolean('is_excluded'),
      boolean('needs_quality_check'),
      createdAt,
      optionalString('exclude_reason'),
      optionalString('thumbnail_path'),
      optionalInt('width'),
      optionalInt('height'),
    );
  }

  ScanImage toDomain() => ScanImage(
    id: id,
    scanId: scanId,
    originalFilename: originalFilename,
    fileSizeBytes: fileSizeBytes,
    mimeType: mimeType,
    format: format,
    sortOrder: sortOrder,
    uploadStatus: uploadStatus,
    isExcluded: isExcluded,
    needsQualityCheck: needsQualityCheck,
    createdAt: createdAt,
    excludeReason: excludeReason,
    thumbnailPath: thumbnailPath,
    width: width,
    height: height,
  );
}

class ScanImageUploadDto {
  ScanImageUploadDto._(this.image, this.scanFileCount, this.scanTotalSizeBytes);
  final ScanImageDto image;
  final int scanFileCount, scanTotalSizeBytes;
  factory ScanImageUploadDto.fromJson(Object? value) {
    final json = _object(value);
    return ScanImageUploadDto._(
      ScanImageDto.fromJson(json['image']),
      _integer(json, 'scan_file_count'),
      _integer(json, 'scan_total_size_bytes'),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

String _string(Map<String, dynamic> json, String key, {bool nonempty = true}) {
  final value = json[key];
  if (value is! String || (nonempty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}
