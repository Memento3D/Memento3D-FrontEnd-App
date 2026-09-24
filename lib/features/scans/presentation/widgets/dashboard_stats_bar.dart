import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardStatsBar extends StatelessWidget {
  final int totalCount;
  final int doneCount;
  final int processingCount;
  final ValueChanged<String>? onFilterTap;

  const DashboardStatsBar({
    super.key,
    required this.totalCount,
    required this.doneCount,
    required this.processingCount,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Tổng Scans',
            count: totalCount,
            color: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFEEF2FF),
            icon: Icons.layers_outlined,
            onTap: () => onFilterTap?.call('all'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Hoàn tất',
            count: doneCount,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            icon: Icons.check_circle_outline_rounded,
            onTap: () => onFilterTap?.call('done'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Đang dựng 3D',
            count: processingCount,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            icon: Icons.hourglass_top_rounded,
            onTap: () => onFilterTap?.call('processing'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Text(
                  count.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
