import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/scan_model.dart';
import '../controllers/scan_state.dart';
import '../widgets/create_scan_dialog.dart';
import '../widgets/edit_scan_dialog.dart';
import '../widgets/scan_card.dart';

/// Dashboard Screen for User 3D Scan Sessions (Issue #43, US-004, FR-004, FR-154)
class DashboardScansScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final ScanState? scanState;

  const DashboardScansScreen({super.key, this.onBackToHome, this.scanState});

  @override
  State<DashboardScansScreen> createState() => _DashboardScansScreenState();
}

class _DashboardScansScreenState extends State<DashboardScansScreen> {
  final _searchController = TextEditingController();

  ScanState get _state => widget.scanState ?? ScanState.instance;

  @override
  void initState() {
    super.initState();
    // Load scans on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.loadScans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateScanSheet() {
    CreateScanBottomSheet.show(context);
  }

  void _openEditDialog(ScanModel scan) {
    EditScanDialog.show(context, scan);
  }

  void _confirmDelete(ScanModel scan) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Xóa phiên scan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa phiên scan "${scan.name}" không? Hành động này có thể hoàn tác trong vòng 90 ngày.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF4B5563),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final success = await _state.deleteScan(scan.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã xóa phiên scan "${scan.name}".'
                            : (_state.errorMessage ??
                                  'Không thể xóa phiên scan.'),
                      ),
                      backgroundColor: success
                          ? const Color(0xFF4B5563)
                          : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Xóa',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final state = _state;
        final filteredScans = state.filteredScans;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => state.loadScans(refresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Top App Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Scans Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Theo dõi và quản lý các phiên tái tạo 3D',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            // + New Scan Action Button
                            ElevatedButton.icon(
                              onPressed: _openCreateScanSheet,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(
                                'Tạo mới',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F0F5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: state.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm phiên scan theo tên...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        state.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 4. Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'all',
                                'Tất cả',
                                state.selectedFilter,
                                state.scans.length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'draft',
                                'Bản nháp',
                                state.selectedFilter,
                                state.scans.where((s) => s.isDraft).length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'processing',
                                'Đang dựng 3D',
                                state.selectedFilter,
                                state.scans.where((s) => s.isProcessing).length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'done',
                                'Hoàn thành',
                                state.selectedFilter,
                                state.scans.where((s) => s.isDone).length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'failed',
                                'Thất bại',
                                state.selectedFilter,
                                state.scans.where((s) => s.isFailed).length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Scans Content (Loading, Empty, or List)
                if (state.isLoading && state.scans.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (filteredScans.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(state.selectedFilter),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final scan = filteredScans[index];
                        return ScanCard(
                          scan: scan,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Phiên scan: ${scan.name} (Trạng thái: ${scan.statusTextVi})',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onEdit: () => _openEditDialog(scan),
                          onDelete: () => _confirmDelete(scan),
                        );
                      }, childCount: filteredScans.length),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    String currentSelected,
    int count,
  ) {
    final isSelected = currentSelected == key;
    return InkWell(
      key: Key('filter_chip_$key'),
      onTap: () => _state.setFilter(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String currentFilter) {
    final hasFilter =
        currentFilter != 'all' || _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilter
                  ? 'Không tìm thấy phiên scan phù hợp'
                  : 'Chưa có phiên scan nào',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Hãy thử thay đổi từ khóa tìm kiếm hoặc chọn bộ lọc trạng thái khác.'
                  : 'Hãy tạo phiên scan đầu tiên để lưu giữ kỷ niệm và số hóa thành mô hình 3D!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _openCreateScanSheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Tạo Phiên Scan Mới ✨',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
