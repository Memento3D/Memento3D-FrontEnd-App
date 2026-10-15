import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/screens/model_viewer_screen.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

import '../../../../screens/capture_session.dart';
import '../../../../screens/processing_screen.dart';
import '../../../../app/photo_capture_flow.dart';

class ScanDetailsSheet extends StatelessWidget {
  final ScanItem scan;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const ScanDetailsSheet({
    super.key,
    required this.scan,
    required this.onRename,
    required this.onDelete,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required ScanItem scan,
    required VoidCallback onRename,
    required VoidCallback onDelete,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ScanDetailsSheet(
        scan: scan,
        onRename: onRename,
        onDelete: onDelete,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Scan Name & Close
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${scan.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Badges row: Status & Mode
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scan.status.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scan.status.icon,
                        size: 13,
                        color: scan.status.textColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        scan.status.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scan.status.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scan.inputMode.icon,
                        size: 13,
                        color: const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        scan.inputMode.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                if (scan.qualityScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Score ${scan.qualityScore}/100',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Info Grid Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F0F5)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Số lượng tệp ảnh/video',
                    '${scan.fileCount} tệp',
                  ),
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  _buildDetailRow('Dung lượng lưu trữ', scan.formattedSize),
                  const Divider(height: 16, color: Color(0xFFE5E7EB)),
                  _buildDetailRow('Thời điểm khởi tạo', scan.formattedDate),
                  if (scan.description != null) ...[
                    const Divider(height: 16, color: Color(0xFFE5E7EB)),
                    _buildDetailRow('Mô tả', scan.description!),
                  ],
                  if (scan.notes != null) ...[
                    const Divider(height: 16, color: Color(0xFFE5E7EB)),
                    _buildDetailRow('Ghi chú chụp', scan.notes!),
                  ],
                  if (scan.errorMessage != null) ...[
                    const Divider(height: 16, color: Color(0xFFE5E7EB)),
                    _buildDetailRow(
                      'Chi tiết lỗi',
                      scan.errorMessage!,
                      isError: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Main CTA (e.g. 3D Preview if Done, Retry if Failed)
            if (scan.isDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModelViewerScreen(
                          scanId: scan.id,
                          scanName: scan.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar_rounded, size: 20),
                  label: const Text('Xem mô hình 3D (3D Viewer)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            if (scan.status == ScanItemStatus.draft)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    // Wizard returns the scan id; the flow then opens camera → review → upload.
                    openCreatedPhotoScanFlow(navigator, scan);
                  },
                  icon: const Icon(Icons.photo_camera_rounded, size: 20),
                  label: const Text('Bắt đầu chụp quét (Guided Wizard)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            if (scan.isProcessing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProcessingScreen(
                          session: CaptureSession(scanId: scan.id),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hourglass_top_rounded, size: 20),
                  label: const Text('Xem tiến trình dựng 3D (Processing)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4FE8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            if (scan.isFailed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Thử lại quá trình dựng 3D'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Secondary Actions: Rename & Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRename();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Đổi tên'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Xóa scan',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
