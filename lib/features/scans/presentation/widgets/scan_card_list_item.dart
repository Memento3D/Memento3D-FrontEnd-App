import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

class ScanCardListItem extends StatelessWidget {
  final ScanItem scan;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const ScanCardListItem({
    super.key,
    required this.scan,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F0F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left: Square Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildThumbnail()),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            scan.inputMode.icon,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Middle: Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: scan.status.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                scan.status.icon,
                                size: 11,
                                color: scan.status.textColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                scan.status.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scan.status.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (scan.qualityScore != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Score ${scan.qualityScore}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      scan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Progress bar or Meta info
                    if (scan.isProcessing && scan.progress != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: scan.progress,
                                backgroundColor: const Color(0xFFF3F4F6),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD97706),
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(scan.progress! * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '${scan.formattedDate} • ${scan.fileCount > 0 ? '${scan.fileCount} tệp' : '0 tệp'} • ${scan.formattedSize}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right: Action Menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'details':
                      onTap();
                      break;
                    case 'rename':
                      onRename();
                      break;
                    case 'retry':
                      onRetry();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF4B5563)),
                        SizedBox(width: 10),
                        Text('Xem chi tiết', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: Color(0xFF4B5563)),
                        SizedBox(width: 10),
                        Text('Đổi tên phiên scan', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (scan.isFailed)
                    const PopupMenuItem(
                      value: 'retry',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: 10),
                          Text('Thử lại (Retry)', style: TextStyle(fontSize: 13, color: Color(0xFFD97706))),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Xóa phiên scan', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (scan.thumbnailAsset != null) {
      return Image.asset(
        scan.thumbnailAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
      );
    }
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: scan.isFailed
              ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
              : scan.isProcessing
                  ? [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFE0E7FF)],
        ),
      ),
      child: Center(
        child: Icon(
          scan.isFailed
              ? Icons.warning_amber_rounded
              : scan.isProcessing
                  ? Icons.view_in_ar_rounded
                  : Icons.view_in_ar_outlined,
          size: 28,
          color: scan.isFailed
              ? const Color(0xFFEF4444)
              : scan.isProcessing
                  ? const Color(0xFFD97706)
                  : AppColors.primary,
        ),
      ),
    );
  }
}
