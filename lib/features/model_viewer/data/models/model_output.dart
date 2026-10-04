import '../../../../core/network/api_config.dart';

/// A single 3D model artifact produced for a scan.
class ModelOutput {
  const ModelOutput({
    required this.id,
    this.scanId,
    this.jobId,
    required this.format,
    this.storagePath,
    this.fileSizeBytes,
    this.fileHash,
    required this.isPrimary,
    this.url,
    this.metadata,
  });

  final String id;
  final String? scanId;
  final String? jobId;
  final String format;
  final String? storagePath;
  final int? fileSizeBytes;
  final String? fileHash;
  final bool isPrimary;
  final String? url;
  final Map<String, dynamic>? metadata;

  bool get isGlb => format.trim().toLowerCase() == 'glb';

  /// Best-effort resolution of a downloadable GLB location.
  String? get downloadUrl {
    final direct = url;
    if (direct != null && direct.isNotEmpty) return direct;
    final path = storagePath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) return '${ApiConfig.baseUrl}$path';
    return '${ApiConfig.baseUrl}/$path';
  }

  factory ModelOutput.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    final metadata = metadataRaw is Map<String, dynamic>
        ? metadataRaw
        : null;
    return ModelOutput(
      id: (json['id'] ?? json['model_output_id'] ?? '').toString(),
      scanId: (json['scan_id'] ?? json['scanId'])?.toString(),
      jobId: (json['job_id'] ?? json['jobId'])?.toString(),
      format: (json['format'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? json['storagePath'])?.toString(),
      fileSizeBytes: _parseSize(json['file_size_bytes'] ?? json['fileSizeBytes']),
      fileHash: (json['file_hash'] ?? json['fileHash'])?.toString(),
      isPrimary: json['is_primary'] == true || json['isPrimary'] == true,
      url: _firstUrl(json, metadata),
      metadata: metadata,
    );
  }

  static int? _parseSize(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static String? _firstUrl(
    Map<String, dynamic> json,
    Map<String, dynamic>? metadata,
  ) {
    const keys = [
      'url',
      'download_url',
      'file_url',
      'presigned_url',
      'public_url',
      'downloadUrl',
      'fileUrl',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
      final metaValue = metadata?[key];
      if (metaValue is String && metaValue.isNotEmpty) return metaValue;
    }
    return null;
  }
}
