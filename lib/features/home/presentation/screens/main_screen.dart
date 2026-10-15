import 'package:flutter/material.dart';

import '../../../../app/photo_capture_flow.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import 'notifications_screen.dart';
import 'addresses_screen.dart';
import 'keepsakes_screen.dart';
import 'shop_screen.dart';
import '../../../orders/presentation/screens/cart_screen.dart';
import '../../../../core/widgets/m3_ui.dart';
import 'desktop_workspace.dart';
import 'mobile_workspace.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/create_scan_dialog.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, this.userName = 'Người dùng'});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
  }

  bool _creationOpen = false;

  Future<void> _editProfile() async {
    final controller = TextEditingController(
      text: AuthState.instance.currentUser?.fullName,
    );
    var saving = false;
    String? error;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('Thông tin tài khoản'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  enabled: !saving,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                if (error != null) Text(error!),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (controller.text.trim().length < 2) {
                          update(
                            () => error = 'Họ tên cần từ 2 đến 100 ký tự.',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await AuthState.instance.updateProfile(
                            controller.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) setState(() {});
                        } catch (failure) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = failure is ApiException
                                  ? failure.message
                                  : failure.toString();
                            });
                          }
                        }
                      },
                child: Text(saving ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openCreateScanDialog() async {
    if (_creationOpen) return;
    _creationOpen = true;
    try {
      final created = await CreateScanDialog.show(
        context,
        onSubmit:
            ({
              required String name,
              required ScanInputMode inputMode,
              String? description,
              String? notes,
            }) async {
              try {
                final created = await ScanRepository.instance.createScanAsync(
                  name: name,
                  inputMode: inputMode,
                  description: description,
                  notes: notes,
                );
                if (mounted) {
                  setState(
                    () => _currentTabIndex = 0,
                  ); // Switch to Dashboard to view new scan
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo phiên scan "$name" thành công! ✨'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
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
                    ),
                  );
                }
                rethrow;
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Không thể tạo phiên scan: ${e.toString()}',
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 1100) {
      return DesktopWorkspace(
        onCreate: _openCreateScanDialog,
        onDashboard: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Bản tạo')),
              body: SafeArea(
                child: MobileWorkspace(
                  onCreate: _openCreateScanDialog,
                  onNotifications: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  onProfile: _openProfile,
                  showAllInitially: true,
                ),
              ),
            ),
          ),
        ),
        onProfile: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Hồ sơ')),
              body: _buildProfileTab(),
            ),
          ),
        ),
        onShop: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ShopScreen())),
        onNotifications: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Studio — tạo scan mới & bản tạo gần đây
          MobileWorkspace(
            onCreate: _openCreateScanDialog,
            onNotifications: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
            onProfile: _openProfile,
          ),

          // Tab 1: Đơn hàng & trạng thái
          OrdersScreen(embedded: true, onProfile: _openProfile),

          // Tab 2: Kỷ vật yêu thích
          KeepsakesScreen(onProfile: _openProfile),

          // Tab 3: Giỏ hàng
          CartScreen(key: _cartKey, embedded: true, onProfile: _openProfile),
        ],
      ),
      bottomNavigationBar: M3BottomNav(
        currentIndex: _currentTabIndex,
        onSelect: (index) {
          _onTabSelected(index);
          if (index == 3) _cartKey.currentState?.reload();
        },
        onCreate: _openCreateScanDialog,
      ),
    );
  }

  final _cartKey = GlobalKey<CartScreenState>();

  void _openProfile() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const M3TopBar(title: 'Hồ sơ', showAvatar: false),
        body: _buildProfileTab(),
      ),
    ),
  );

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                  onTap: _editProfile,
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.lock_outline_rounded,
                  title: 'Bảo mật & Đổi mật khẩu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.receipt_long_outlined,
                  title: 'Đơn hàng của tôi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrdersScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.location_on_outlined,
                  title: 'Địa chỉ giao hàng',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddressesScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F0F5)),
                _buildProfileOption(
                  icon: Icons.storefront_outlined,
                  title: 'Sản phẩm và giỏ hàng',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                  ),
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
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
