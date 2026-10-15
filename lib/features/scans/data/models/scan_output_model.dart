/// A single generated output file for a scan (e.g. the primary GLB mesh,
/// an OBJ export, a preview thumbnail, ...).
///
/// Maps the response of `GET /api/v1/scans/{id}/outputs`.
class ScanOutputModel {
  final String id;
  final String format; // e.g. "glb", "obj", "usdz"
  final String fileUrl;
  final String? thumbnailUrl;
  final int fileSizeBytes;
  final bool isPrimary;
  final String? status;
  final DateTime? createdAt;

  const ScanOutputModel({
    required this.id,
    required this.format,
    required this.fileUrl,
    this.thumbnailUrl,
    this.fileSizeBytes = 0,
    this.isPrimary = false,
    this.status,
    this.createdAt,
  });

  bool get isGlb => format.toLowerCase() == 'glb';

  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 KB';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory ScanOutputModel.fromJson(Map<String, dynamic> json) {
    return ScanOutputModel(
      id: (json['id'] ?? json['output_id'] ?? json['outputId'] ?? '')
          .toString(),
      format: (json['format'] ?? json['fileFormat'] ?? json['type'] ?? 'glb')
          .toString(),
      fileUrl:
          (json['delivery_url'] ??
                  json['deliveryUrl'] ??
                  json['fileUrl'] ??
                  json['file_url'] ??
                  json['url'] ??
                  '')
              .toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? json['thumbnail_url'])?.toString(),
      fileSizeBytes: _asInt(
        json['fileSizeBytes'] ?? json['file_size_bytes'] ?? json['sizeBytes'],
      ),
      isPrimary: (json['isPrimary'] ?? json['is_primary'] ?? false) == true,
      status: json['status']?.toString(),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// Wrapper for the list response of `GET /api/v1/scans/{id}/outputs`.
/// Backend may return a bare JSON array or an object wrapping it under
/// `outputs` / `data` — both shapes are accepted.
class ScanOutputsResponseModel {
  final List<ScanOutputModel> outputs;

  const ScanOutputsResponseModel({required this.outputs});

  factory ScanOutputsResponseModel.fromDynamic(dynamic json) {
    List<dynamic> rawList;
    if (json is List) {
      rawList = json;
    } else if (json is Map<String, dynamic>) {
      final candidate = json['outputs'] ?? json['data'] ?? json['items'];
      rawList = candidate is List ? candidate : const [];
    } else {
      rawList = const [];
    }

    return ScanOutputsResponseModel(
      outputs: rawList
          .whereType<Map<String, dynamic>>()
          .map(ScanOutputModel.fromJson)
          .toList(),
    );
  }

  /// Picks the output to display in the viewer: the explicit primary GLB,
  /// else the first GLB, else just the first output available.
  ScanOutputModel? get primaryOutput {
    if (outputs.isEmpty) return null;
    for (final o in outputs) {
      if (o.isPrimary && o.isGlb) return o;
    }
    for (final o in outputs) {
      if (o.isGlb) return o;
    }
    return outputs.first;
  }
}
