import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';

class ScanEmptyState extends StatelessWidget {
  final bool isSearchOrFilter;
  final VoidCallback onCreateScan;
  final VoidCallback? onResetFilter;

  const ScanEmptyState({
    super.key,
    required this.isSearchOrFilter,
    required this.onCreateScan,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchOrFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy phiên scan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Không có kết quả nào khớp với tìm kiếm hoặc bộ lọc hiện tại của bạn.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chưa có phiên scan nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu số hóa kỷ niệm và biến những khoảnh khắc yêu thương thành tượng 3D Keepsake tuyệt đẹp!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onCreateScan,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tạo Scan Mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
