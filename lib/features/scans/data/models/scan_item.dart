import 'package:flutter/material.dart';

/// Capture mode for a scan session
enum ScanInputMode {
  image,
  video;

  String get displayName {
    switch (this) {
      case ScanInputMode.image:
        return 'Ảnh (30-100)';
      case ScanInputMode.video:
        return 'Video HD';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanInputMode.image:
        return Icons.photo_camera_rounded;
      case ScanInputMode.video:
        return Icons.videocam_rounded;
    }
  }
}

/// Lifecycle status of a scan session (matching backend ScanStatus)
enum ScanItemStatus {
  draft,
  uploading,
  uploaded,
  qualityCheck,
  ready,
  processing,
  done,
  failed,
  deleted;

  String get displayName {
    switch (this) {
      case ScanItemStatus.draft:
        return 'Bản nháp';
      case ScanItemStatus.uploading:
        return 'Đang tải lên';
      case ScanItemStatus.uploaded:
        return 'Đã tải lên';
      case ScanItemStatus.qualityCheck:
        return 'Kiểm tra ảnh';
      case ScanItemStatus.ready:
        return 'Sẵn sàng dựng';
      case ScanItemStatus.processing:
        return 'Đang xử lý';
      case ScanItemStatus.done:
        return 'Hoàn tất';
      case ScanItemStatus.failed:
        return 'Lỗi xử lý';
      case ScanItemStatus.deleted:
        return 'Đã xoá';
    }
  }

  Color get textColor {
    switch (this) {
      case ScanItemStatus.done:
        return const Color(0xFF047857); // Emerald dark
      case ScanItemStatus.processing:
      case ScanItemStatus.uploading:
      case ScanItemStatus.qualityCheck:
        return const Color(0xFFB45309); // Amber dark
      case ScanItemStatus.failed:
        return const Color(0xFFB91C1C); // Crimson dark
      case ScanItemStatus.ready:
        return const Color(0xFF6D28D9); // Violet dark
      case ScanItemStatus.draft:
      case ScanItemStatus.uploaded:
      case ScanItemStatus.deleted:
        return const Color(0xFF4B5563); // Gray dark
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ScanItemStatus.done:
        return const Color(0xFFD1FAE5); // Emerald light
      case ScanItemStatus.processing:
      case ScanItemStatus.uploading:
      case ScanItemStatus.qualityCheck:
        return const Color(0xFFFEF3C7); // Amber light
      case ScanItemStatus.failed:
        return const Color(0xFFFEE2E2); // Crimson light
      case ScanItemStatus.ready:
        return const Color(0xFFEDE9FE); // Violet light
      case ScanItemStatus.draft:
      case ScanItemStatus.uploaded:
      case ScanItemStatus.deleted:
        return const Color(0xFFF3F4F6); // Gray light
    }
  }

  IconData get icon {
    switch (this) {
      case ScanItemStatus.done:
        return Icons.check_circle_rounded;
      case ScanItemStatus.processing:
        return Icons.sync_rounded;
      case ScanItemStatus.uploading:
        return Icons.cloud_upload_rounded;
      case ScanItemStatus.qualityCheck:
        return Icons.verified_outlined;
      case ScanItemStatus.ready:
        return Icons.play_arrow_rounded;
      case ScanItemStatus.failed:
        return Icons.error_outline_rounded;
      case ScanItemStatus.draft:
        return Icons.edit_note_rounded;
      case ScanItemStatus.uploaded:
        return Icons.cloud_done_rounded;
      case ScanItemStatus.deleted:
        return Icons.delete_outline_rounded;
    }
  }
}

/// Model representing a scan session on the Dashboard
class ScanItem {
  final String id;
  final String name;
  final String? description;
  final String? notes;
  final ScanInputMode inputMode;
  final ScanItemStatus status;
  final int fileCount;
  final int totalSizeBytes;
  final String? thumbnailAsset;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? progress; // 0.0 - 1.0 for ongoing processing
  final int? qualityScore; // 0 - 100
  final String? errorMessage;

  const ScanItem({
    required this.id,
    required this.name,
    this.description,
    this.notes,
    required this.inputMode,
    required this.status,
    required this.fileCount,
    required this.totalSizeBytes,
    this.thumbnailAsset,
    required this.createdAt,
    this.updatedAt,
    this.progress,
    this.qualityScore,
    this.errorMessage,
  });

  bool get isProcessing =>
      status == ScanItemStatus.processing ||
      status == ScanItemStatus.uploading ||
      status == ScanItemStatus.qualityCheck;

  bool get isDone => status == ScanItemStatus.done;
  bool get isFailed => status == ScanItemStatus.failed;
  bool get isDraft => status == ScanItemStatus.draft;

  String get formattedSize {
    if (totalSizeBytes <= 0) return '0 KB';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Vừa xong' : '$mins phút trước';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    return '$day/$month/$year';
  }

  ScanItem copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    ScanInputMode? inputMode,
    ScanItemStatus? status,
    int? fileCount,
    int? totalSizeBytes,
    String? thumbnailAsset,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progress,
    int? qualityScore,
    String? errorMessage,
  }) {
    return ScanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      inputMode: inputMode ?? this.inputMode,
      status: status ?? this.status,
      fileCount: fileCount ?? this.fileCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
      qualityScore: qualityScore ?? this.qualityScore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
