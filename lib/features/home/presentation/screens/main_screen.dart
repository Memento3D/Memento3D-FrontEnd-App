import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/home_tab_view.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/dashboard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_wizard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/create_scan_dialog.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({
    super.key,
    this.userName = 'Người dùng',
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
  }

  void _openCreateScanDialog() {
    CreateScanDialog.show(
      context,
      onSubmit: ({
        required String name,
        required ScanInputMode inputMode,
        String? description,
        String? notes,
      }) {
        final newScan = ScanRepository.instance.createScanOptimistic(
          name: name,
          inputMode: inputMode,
          description: description,
          notes: notes,
        );

        if (mounted) {
          setState(() => _currentTabIndex = 0); // Switch to Dashboard to view new scan
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanWizardScreen(
                scanId: newScan.id,
                scanName: newScan.name,
              ),
            ),
          );
        }
      },
    );
  }

  void _openCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
                Text(
                  'Tạo phiên Scan & Kỷ niệm 3D ✨',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Số hóa kỷ niệm thành mô hình 3D hoặc đặt in Keepsake',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionTile(
                  icon: Icons.view_in_ar_rounded,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Tạo phiên Scan 3D mới',
                  subtitle: 'Bắt đầu quy trình Guided Capture Wizard',
                  onTap: () {
                    Navigator.pop(context);
                    _openCreateScanDialog();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.photo_camera_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Chụp ảnh vật thể',
                  subtitle: 'Mở máy ảnh chụp trực tiếp góc 360 độ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScanWizardScreen(
                          scanId: 'scan_${DateTime.now().millisecondsSinceEpoch}',
                          scanName: 'Chụp ảnh 360°',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.photo_library_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Chọn ảnh từ thư viện',
                  subtitle: 'Tải bộ ảnh có sẵn lên để tái tạo 3D',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang mở thư viện ảnh...')),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F0F5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // Tab 0: Dashboard (Danh sách phiên Scan - Điểm vào chính sau khi đăng nhập)
            DashboardScreen(
              userName: widget.userName,
              onNavigateToProfile: () => _onTabSelected(4),
            ),

            // Tab 1: Khám phá Keepsake & Kỷ niệm
            HomeTabView(
              onCreateKeepsake: _openCreateBottomSheet,
            ),

            // Tab 2: Dummy for Center FAB (won't be directly indexed)
            const SizedBox.shrink(),

            // Tab 3: Keepsakes
            _buildPlaceholderTab(
              icon: Icons.view_in_ar_rounded,
              title: 'Your Keepsakes',
              subtitle: 'Bộ sưu tập tượng 3D Keepsake đã hoàn thiện.',
            ),

            // Tab 4: Profile
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildProfileTab() {
    final user = AuthState.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            'Hồ sơ cá nhân',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),

          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F0F5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Người dùng Memento3D',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Chưa xác định email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.role ?? 'USER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Options
          Text(
            'Tài khoản & Cài đặt',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F0F5)),
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  icon: Icons.person_outline_rounded,
                  title: 'Thông tin tài khoản',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.lock_outline_rounded,
                  title: 'Bảo mật & Đổi mật khẩu',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp & Hỗ trợ',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              label: Text(
                'Đăng xuất',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFEE2E2)),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFF9CA3AF),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Đăng xuất',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF4B5563),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                Navigator.of(dialogContext).pop();
                await AuthState.instance.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã đăng xuất thành công.'),
                      backgroundColor: const Color(0xFF4B5563),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF1F0F5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Dashboard (My Scans)
          _buildNavItem(
            index: 0,
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),

          // 2. Khám phá (Showcase)
          _buildNavItem(
            index: 1,
            icon: Icons.explore_outlined,
            label: 'Khám phá',
          ),

          // 3. Center FAB (+)
          GestureDetector(
            onTap: _openCreateScanDialog,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // 4. Keepsakes
          _buildNavItem(
            index: 3,
            icon: Icons.view_in_ar_rounded,
            label: 'Keepsakes',
          ),

          // 5. Profile
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
