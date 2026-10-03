import 'package:flutter/material.dart';

/// Data model representing a 3D Scan Session
class ScanModel {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String? notes;
  final String inputMode; // 'image' or 'video'
  final String status; // 'draft', 'uploaded', 'processing', 'done', 'failed', 'deleted'
  final int fileCount;
  final int totalSizeBytes;
  final String? thumbnailPath;
  final Map<String, dynamic>? deviceInfo;
  final String? duplicatedFrom;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ScanModel({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.notes,
    this.inputMode = 'image',
    this.status = 'draft',
    this.fileCount = 0,
    this.totalSizeBytes = 0,
    this.thumbnailPath,
    this.deviceInfo,
    this.duplicatedFrom,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      notes: json['notes']?.toString(),
      inputMode: json['input_mode']?.toString() ?? json['inputMode']?.toString() ?? 'image',
      status: json['status']?.toString() ?? 'draft',
      fileCount: (json['file_count'] ?? json['fileCount'] as num?)?.toInt() ?? 0,
      totalSizeBytes: (json['total_size_bytes'] ?? json['totalSizeBytes'] as num?)?.toInt() ?? 0,
      thumbnailPath: json['thumbnail_path']?.toString() ?? json['thumbnailPath']?.toString(),
      deviceInfo: json['device_info'] is Map<String, dynamic>
          ? json['device_info'] as Map<String, dynamic>
          : (json['deviceInfo'] is Map<String, dynamic> ? json['deviceInfo'] as Map<String, dynamic> : null),
      duplicatedFrom: json['duplicated_from']?.toString() ?? json['duplicatedFrom']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal() : null),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : (json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString())?.toLocal() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'notes': notes,
      'input_mode': inputMode,
      'status': status,
      'file_count': fileCount,
      'total_size_bytes': totalSizeBytes,
      'thumbnail_path': thumbnailPath,
      'device_info': deviceInfo,
      'duplicated_from': duplicatedFrom,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  ScanModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? notes,
    String? inputMode,
    String? status,
    int? fileCount,
    int? totalSizeBytes,
    String? thumbnailPath,
    Map<String, dynamic>? deviceInfo,
    String? duplicatedFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ScanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      inputMode: inputMode ?? this.inputMode,
      status: status ?? this.status,
      fileCount: fileCount ?? this.fileCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      duplicatedFrom: duplicatedFrom ?? this.duplicatedFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Convenience getters
  bool get isImageMode => inputMode.toLowerCase() == 'image';
  bool get isVideoMode => inputMode.toLowerCase() == 'video';

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isUploaded => status.toLowerCase() == 'uploaded';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isDone => status.toLowerCase() == 'done';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isDeleted => status.toLowerCase() == 'deleted';

  String get inputModeTextVi => isImageMode ? 'Chế độ ảnh' : 'Chế độ video';

  String get statusTextVi {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Bản nháp';
      case 'uploaded':
        return 'Đã tải lên';
      case 'processing':
        return 'Đang dựng 3D';
      case 'done':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      case 'deleted':
        return 'Đã xóa';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'done':
        return const Color(0xFF10B981); // Emerald Green
      case 'processing':
        return const Color(0xFFF59E0B); // Amber Warning
      case 'failed':
        return const Color(0xFFEF4444); // Red Error
      case 'uploaded':
        return const Color(0xFF3B82F6); // Blue
      case 'draft':
      default:
        return const Color(0xFF8B5CF6); // Purple/Violet
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'done':
        return const Color(0xFFECFDF5);
      case 'processing':
        return const Color(0xFFFFFBEB);
      case 'failed':
        return const Color(0xFFFEF2F2);
      case 'uploaded':
        return const Color(0xFFEFF6FF);
      case 'draft':
      default:
        return const Color(0xFFF5F3FF);
    }
  }

  String get formattedDate {
    if (createdAt == null) return 'Không rõ thời gian';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24 && createdAt!.day == now.day) {
      final hourStr = createdAt!.hour.toString().padLeft(2, '0');
      final minStr = createdAt!.minute.toString().padLeft(2, '0');
      return 'Hôm nay, $hourStr:$minStr';
    } else {
      final day = createdAt!.day.toString().padLeft(2, '0');
      final month = createdAt!.month.toString().padLeft(2, '0');
      final year = createdAt!.year;
      return '$day/$month/$year';
    }
  }

  String get formattedSize {
    if (totalSizeBytes <= 0) return '0 KB';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// Request DTO for creating a scan session
class CreateScanRequestModel {
  final String name;
  final String? description;
  final String? notes;
  final String inputMode;

  const CreateScanRequestModel({
    required this.name,
    this.description,
    this.notes,
    this.inputMode = 'image',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'input_mode': inputMode,
    };
    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }
    return map;
  }
}

/// Paginated scan list response model
class ScanListResponseModel {
  final List<ScanModel> scans;
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  const ScanListResponseModel({
    required this.scans,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ScanListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['scans'] ?? json['items'];
    final scansList = <ScanModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          scansList.add(ScanModel.fromJson(item));
        }
      }
    }

    return ScanListResponseModel(
      scans: scansList,
      totalCount: (json['total_count'] ?? json['totalCount'] as num?)?.toInt() ?? scansList.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['total_pages'] ?? json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Response DTO for POST /api/v1/scans/{id}/job (US-027, FR-081, FR-082, FR-199)
///
/// The backend returns 202 Accepted with the created (or, on a repeated
/// request for the same scan, the already-existing) job id.
class ReconstructionJobModel {
  final String jobId;
  final String scanId;
  final String status; // 'queued', 'extracting', ... (see UC-05 pipeline stages)
  final int? queuePosition;
  final DateTime? createdAt;

  const ReconstructionJobModel({
    required this.jobId,
    required this.scanId,
    this.status = 'queued',
    this.queuePosition,
    this.createdAt,
  });

  factory ReconstructionJobModel.fromJson(Map<String, dynamic> json) {
    return ReconstructionJobModel(
      jobId: json['job_id']?.toString() ?? json['jobId']?.toString() ?? json['id']?.toString() ?? '',
      scanId: json['scan_id']?.toString() ?? json['scanId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'queued',
      queuePosition: (json['queue_position'] ?? json['queuePosition'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() : null),
    );
  }
}
