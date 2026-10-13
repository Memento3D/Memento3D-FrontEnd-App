import 'package:flutter/material.dart';
import '../../../../app/photo_capture_flow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/create_scan_dialog.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/dashboard_stats_bar.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/rename_scan_dialog.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/scan_card_grid_item.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/scan_card_list_item.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/scan_details_sheet.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/scan_empty_state.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onNavigateToProfile;

  const DashboardScreen({
    super.key,
    this.userName = 'Người dùng',
    this.onNavigateToProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = ScanRepository.instance;
  final _searchController = TextEditingController();

  String _statusFilter = 'all';
  String _sortBy = 'newest';
  bool _isGridView = true;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _loadScans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load scans from Backend API (GET /api/v1/scans)
  Future<void> _loadScans({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.fetchScans(
        statusFilter: _statusFilter,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        refresh: refresh,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException
              ? e.message
              : 'Không thể kết nối đến máy chủ backend: ${e.toString()}';
        });
      }
    }
  }

  /// Create a new scan session via Backend API (POST /api/v1/scans)
  bool _creationOpen = false;

  Future<void> _openCreateScan() async {
    if (_creationOpen) return;
    _creationOpen = true;
    try {
      final created = await CreateScanDialog.show(
        context,
        onSubmit: ({
          required String name,
          required ScanInputMode inputMode,
          String? description,
          String? notes,
        }) async {
          try {
            final created = await _repository.createScanAsync(
              name: name,
              inputMode: inputMode,
              description: description,
              notes: notes,
            );
            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã tạo phiên scan "$name" thành công! ✨'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            return created;
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            rethrow;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Không thể tạo phiên scan: ${e.toString()}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
            rethrow;
          }
        },
      );
      if (mounted && created != null) {
        await openCreatedPhotoScanFlow(Navigator.of(context), created);
      }
    } finally {
      _creationOpen = false;
    }
  }

  /// Rename a scan session via Backend API (PATCH /api/v1/scans/{id})
  void _openRenameScan(ScanItem scan) {
    RenameScanDialog.show(
      context,
      scan: scan,
      onRename: (newName) async {
        try {
          final updated = await _repository.updateScanNameAsync(scan.id, newName);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã đổi tên thành "${updated?.name ?? newName}"'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } on ApiException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          rethrow;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể đổi tên: ${e.toString()}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          rethrow;
        }
      },
    );
  }

  /// Soft-delete scan session via Backend API (DELETE /api/v1/scans/{id})
  void _confirmDeleteScan(ScanItem scan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa phiên scan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${scan.name}"? Dữ liệu scan sẽ được chuyển vào mục lưu trữ tạm thời (soft-delete).',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
              try {
                await _repository.deleteScanAsync(scan.id);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa phiên scan "${scan.name}"'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể xóa phiên scan: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _handleRetry(ScanItem scan) {
    setState(() {
      _repository.retryScan(scan.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang khởi động lại phiên dựng 3D cho "${scan.name}"...'),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openDetailsSheet(ScanItem scan) {
    ScanDetailsSheet.show(
      context,
      scan: scan,
      onRename: () => _openRenameScan(scan),
      onDelete: () => _confirmDeleteScan(scan),
      onRetry: () => _handleRetry(scan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scans = _repository.getScans(
      statusFilter: _statusFilter,
      searchQuery: _searchQuery,
      sortBy: _sortBy,
    );
    final metrics = _repository.getSummaryMetrics();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScan,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Tạo Scan Mới',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadScans(refresh: true),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Top Bar & Greeting Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: _buildHeader(),
                ),
              ),

              // Subtle Loading Indicator when syncing with backend
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    minHeight: 2.5,
                  ),
                ),

              // Error Banner if backend synchronization fails
              if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _loadScans(refresh: true),
                          child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Quick Stats Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DashboardStatsBar(
                    totalCount: metrics['total'] ?? 0,
                    doneCount: metrics['done'] ?? 0,
                    processingCount: metrics['processing'] ?? 0,
                    onFilterTap: (filter) {
                      setState(() => _statusFilter = filter);
                    },
                  ),
                ),
              ),

              // 4. Search & Controls Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterAndSortRow(scans.length),
                    ],
                  ),
                ),
              ),

              // 5. Scans Grid or List or Empty State
              if (scans.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ScanEmptyState(
                    isSearchOrFilter: _searchQuery.isNotEmpty || _statusFilter != 'all',
                    onCreateScan: _openCreateScan,
                    onResetFilter: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _statusFilter = 'all';
                      });
                    },
                  ),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final scan = scans[index];
                        return ScanCardGridItem(
                          scan: scan,
                          onTap: () => _openDetailsSheet(scan),
                          onRename: () => _openRenameScan(scan),
                          onDelete: () => _confirmDeleteScan(scan),
                          onRetry: () => _handleRetry(scan),
                        );
                      },
                      childCount: scans.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final scan = scans[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ScanCardListItem(
                            scan: scan,
                            onTap: () => _openDetailsSheet(scan),
                            onRename: () => _openRenameScan(scan),
                            onDelete: () => _confirmDeleteScan(scan),
                            onRetry: () => _handleRetry(scan),
                          ),
                        );
                      },
                      childCount: scans.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: widget.onNavigateToProfile,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.userName.trim().isNotEmpty
                        ? widget.userName.trim()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${widget.userName}! 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Dashboard • Danh sách phiên Scan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Notification Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F0F5)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF374151),
                  size: 20,
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thông báo: 1 phiên scan vừa hoàn tất tái tạo 3D!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên scan, ghi chú...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterAndSortRow(int count) {
    return Column(
      children: [
        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('all', 'Tất cả'),
              const SizedBox(width: 8),
              _buildFilterChip('done', 'Hoàn tất'),
              const SizedBox(width: 8),
              _buildFilterChip('processing', 'Đang xử lý'),
              const SizedBox(width: 8),
              _buildFilterChip('failed', 'Lỗi'),
              const SizedBox(width: 8),
              _buildFilterChip('draft', 'Bản nháp'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Controls bar: count, sort, and view mode toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$count phiên scan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            Row(
              children: [
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                        DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                        DropdownMenuItem(value: 'name_asc', child: Text('Tên A-Z')),
                        DropdownMenuItem(value: 'size_desc', child: Text('Dung lượng')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Grid / List toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          Icons.grid_view_rounded,
                          size: 17,
                          color: _isGridView ? AppColors.primary : const Color(0xFF9CA3AF),
                        ),
                        onPressed: () => setState(() => _isGridView = true),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          Icons.view_agenda_rounded,
                          size: 17,
                          color: !_isGridView ? AppColors.primary : const Color(0xFF9CA3AF),
                        ),
                        onPressed: () => setState(() => _isGridView = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
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
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
