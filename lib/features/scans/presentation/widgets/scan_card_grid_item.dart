import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

class ScanCardGridItem extends StatelessWidget {
  final ScanItem scan;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const ScanCardGridItem({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F0F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildThumbnail(),
                  ),
                  // Top Input Mode Tag
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            scan.inputMode.icon,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scan.inputMode == ScanInputMode.image ? 'Ảnh' : 'Video',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right 3-dots Menu
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildPopupMenu(context),
                  ),

                  // If Processing: Overlay with ETA / Progress
                  if (scan.isProcessing && scan.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Dựng 3D: ${(scan.progress! * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
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
                  const SizedBox(height: 6),

                  // Scan Name
                  Text(
                    scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Metadata: Date & File size
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scan.formattedDate,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      Text(
                        '${scan.fileCount > 0 ? '${scan.fileCount} tệp' : ''} ${scan.totalSizeBytes > 0 ? '• ${scan.formattedSize}' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          size: 38,
          color: scan.isFailed
              ? const Color(0xFFEF4444)
              : scan.isProcessing
                  ? const Color(0xFFD97706)
                  : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Color(0xFF374151),
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
    );
  }
}
